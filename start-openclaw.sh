#!/bin/bash
# Startup script for OpenClaw in Cloudflare Sandbox
# This script:
# 1. Restores config from R2 backup if available
# 2. Restores workspace (IDENTITY.md, MEMORY.md, etc.) from R2
# 3. Runs openclaw onboard --non-interactive to configure from env vars
# 4. Patches config for features onboard doesn't cover (channels, gateway auth)
# 5. Starts the gateway

set -e

if pgrep -f "openclaw gateway" > /dev/null 2>&1; then
    echo "OpenClaw gateway is already running, exiting."
    exit 0
fi

CONFIG_DIR="/root/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
BACKUP_DIR="/data/moltbot"
WORKSPACE_DIR="/root/.openclaw/workspace"

echo "Config directory: $CONFIG_DIR"
echo "Backup directory: $BACKUP_DIR"
echo "Workspace directory: $WORKSPACE_DIR"

mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"

# ============================================================
# RESTORE FROM R2 BACKUP
# ============================================================

should_restore_from_r2() {
    local R2_SYNC_FILE="$BACKUP_DIR/.last-sync"
    local LOCAL_SYNC_FILE="$CONFIG_DIR/.last-sync"

    if [ ! -f "$R2_SYNC_FILE" ]; then
        echo "No R2 sync timestamp found, skipping restore"
        return 1
    fi

    if [ ! -f "$LOCAL_SYNC_FILE" ]; then
        echo "No local sync timestamp, will restore from R2"
        return 0
    fi

    R2_TIME=$(cat "$R2_SYNC_FILE" 2>/dev/null)
    LOCAL_TIME=$(cat "$LOCAL_SYNC_FILE" 2>/dev/null)

    echo "R2 last sync: $R2_TIME"
    echo "Local last sync: $LOCAL_TIME"

    R2_EPOCH=$(date -d "$R2_TIME" +%s 2>/dev/null || echo "0")
    LOCAL_EPOCH=$(date -d "$LOCAL_TIME" +%s 2>/dev/null || echo "0")

    if [ "$R2_EPOCH" -gt "$LOCAL_EPOCH" ]; then
        echo "R2 backup is newer, will restore"
        return 0
    else
        echo "Local data is newer or same, skipping restore"
        return 1
    fi
}

# Check for backup data in new openclaw/ prefix first, then legacy clawdbot/ prefix
if [ -f "$BACKUP_DIR/openclaw/openclaw.json" ]; then
    if should_restore_from_r2; then
        echo "Restoring from R2 backup at $BACKUP_DIR/openclaw..."
        cp -a "$BACKUP_DIR/openclaw/." "$CONFIG_DIR/"
        cp -f "$BACKUP_DIR/.last-sync" "$CONFIG_DIR/.last-sync" 2>/dev/null || true
        echo "Restored config from R2 backup"
    fi
elif [ -f "$BACKUP_DIR/clawdbot/clawdbot.json" ]; then
    if should_restore_from_r2; then
        echo "Restoring from legacy R2 backup at $BACKUP_DIR/clawdbot..."
        cp -a "$BACKUP_DIR/clawdbot/." "$CONFIG_DIR/"
        cp -f "$BACKUP_DIR/.last-sync" "$CONFIG_DIR/.last-sync" 2>/dev/null || true
        if [ -f "$CONFIG_DIR/clawdbot.json" ] && [ ! -f "$CONFIG_FILE" ]; then
            mv "$CONFIG_DIR/clawdbot.json" "$CONFIG_FILE"
        fi
        echo "Restored and migrated config from legacy R2 backup"
    fi
elif [ -d "$BACKUP_DIR" ]; then
    echo "R2 mounted at $BACKUP_DIR but no config backup found yet"
else
    echo "R2 not mounted, starting fresh"
fi

# ============================================================
# RESTORE WORKSPACE FROM R2
# ============================================================
# Workspace files: IDENTITY.md, USER.md, MEMORY.md, SOUL.md, TOOLS.md, HEARTBEAT.md, AGENTS.md
# Plus directories: memory/, skills/

R2_WORKSPACE="$BACKUP_DIR/openclaw-workspace"

if [ -d "$R2_WORKSPACE" ] && [ "$(ls -A $R2_WORKSPACE 2>/dev/null)" ]; then
    if should_restore_from_r2; then
        echo "Restoring workspace from $R2_WORKSPACE..."
        
        # Restore individual workspace files
        for file in IDENTITY.md USER.md MEMORY.md SOUL.md TOOLS.md HEARTBEAT.md AGENTS.md; do
            if [ -f "$R2_WORKSPACE/$file" ]; then
                cp "$R2_WORKSPACE/$file" "$WORKSPACE_DIR/$file"
                echo "  Restored: $file"
            fi
        done
        
        # Restore memory directory
        if [ -d "$R2_WORKSPACE/memory" ]; then
            mkdir -p "$WORKSPACE_DIR/memory"
            cp -r "$R2_WORKSPACE/memory/." "$WORKSPACE_DIR/memory/"
            echo "  Restored: memory/"
        fi
        
        # Restore skills directory
        if [ -d "$R2_WORKSPACE/skills" ]; then
            mkdir -p "$WORKSPACE_DIR/skills"
            cp -r "$R2_WORKSPACE/skills/." "$WORKSPACE_DIR/skills/"
            echo "  Restored: skills/"
        fi
        
        # Copy sync timestamp
        cp -f "$BACKUP_DIR/.last-sync" "$WORKSPACE_DIR/.last-sync" 2>/dev/null || true
        
        echo "Workspace restored from R2"
    fi
else
    echo "No workspace backup found at $R2_WORKSPACE"
fi

# ============================================================
# RESTORE SCRIPTS FROM R2 (if available)
# ============================================================
if [ -d "$BACKUP_DIR/openclaw/scripts" ]; then
    echo "Restoring sync scripts from R2..."
    mkdir -p "$CONFIG_DIR/scripts"
    cp -a "$BACKUP_DIR/openclaw/scripts/." "$CONFIG_DIR/scripts/"
    chmod +x "$CONFIG_DIR/scripts/"*.sh 2>/dev/null || true
    echo "Scripts restored"
fi

# ============================================================
# ONBOARD (only if no config exists yet)
# ============================================================
if [ ! -f "$CONFIG_FILE" ]; then
    echo "No existing config found, running openclaw onboard..."

    AUTH_ARGS=""
    if [ -n "$CLOUDFLARE_AI_GATEWAY_API_KEY" ] && [ -n "$CF_AI_GATEWAY_ACCOUNT_ID" ] && [ -n "$CF_AI_GATEWAY_GATEWAY_ID" ]; then
        AUTH_ARGS="--auth-choice cloudflare-ai-gateway-api-key \
            --cloudflare-ai-gateway-account-id $CF_AI_GATEWAY_ACCOUNT_ID \
            --cloudflare-ai-gateway-gateway-id $CF_AI_GATEWAY_GATEWAY_ID \
            --cloudflare-ai-gateway-api-key $CLOUDFLARE_AI_GATEWAY_API_KEY"
    elif [ -n "$ANTHROPIC_API_KEY" ]; then
        AUTH_ARGS="--auth-choice apiKey --anthropic-api-key $ANTHROPIC_API_KEY"
    elif [ -n "$OPENAI_API_KEY" ]; then
        AUTH_ARGS="--auth-choice openai-api-key --openai-api-key $OPENAI_API_KEY"
    fi

    openclaw onboard --non-interactive --accept-risk \
        --mode local \
        $AUTH_ARGS \
        --gateway-port 18789 \
        --gateway-bind lan \
        --skip-channels \
        --skip-skills \
        --skip-health

    echo "Onboard completed"
else
    echo "Using existing config"
fi

# ============================================================
# PATCH CONFIG (channels, gateway auth, trusted proxies)
# ============================================================
node << 'EOFPATCH'
const fs = require('fs');

const configPath = '/root/.openclaw/openclaw.json';
console.log('Patching config at:', configPath);
let config = {};

try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (e) {
    console.log('Starting with empty config');
}

config.gateway = config.gateway || {};
config.channels = config.channels || {};

// Gateway configuration
config.gateway.port = 18789;
config.gateway.mode = 'local';
config.gateway.trustedProxies = ['10.1.0.0'];

if (process.env.OPENCLAW_GATEWAY_TOKEN) {
    config.gateway.auth = config.gateway.auth || {};
    config.gateway.auth.token = process.env.OPENCLAW_GATEWAY_TOKEN;
}

// Control UI configuration for proxied CF Worker deployment
// CF Access provides authentication at the worker level, so we disable
// device pairing for the Control UI (would require pairing on every container restart)
config.gateway.controlUi = config.gateway.controlUi || {};
config.gateway.controlUi.dangerouslyDisableDeviceAuth = true;
config.gateway.controlUi.allowInsecureAuth = true;
console.log('Device auth disabled for proxied deployment (CF Access provides auth)');

// AI Gateway model override
if (process.env.CF_AI_GATEWAY_MODEL) {
    const raw = process.env.CF_AI_GATEWAY_MODEL;
    const slashIdx = raw.indexOf('/');
    const gwProvider = raw.substring(0, slashIdx);
    const modelId = raw.substring(slashIdx + 1);

    const accountId = process.env.CF_AI_GATEWAY_ACCOUNT_ID;
    const gatewayId = process.env.CF_AI_GATEWAY_GATEWAY_ID;
    const apiKey = process.env.CLOUDFLARE_AI_GATEWAY_API_KEY;

    let baseUrl;
    if (accountId && gatewayId) {
        baseUrl = 'https://gateway.ai.cloudflare.com/v1/' + accountId + '/' + gatewayId + '/' + gwProvider;
        if (gwProvider === 'workers-ai') baseUrl += '/v1';
    } else if (gwProvider === 'workers-ai' && process.env.CF_ACCOUNT_ID) {
        baseUrl = 'https://api.cloudflare.com/client/v4/accounts/' + process.env.CF_ACCOUNT_ID + '/ai/v1';
    }

    if (baseUrl && apiKey) {
        const api = gwProvider === 'anthropic' ? 'anthropic-messages' : 'openai-completions';
        const providerName = 'cf-ai-gw-' + gwProvider;

        config.models = config.models || {};
        config.models.providers = config.models.providers || {};
        config.models.providers[providerName] = {
            baseUrl: baseUrl,
            apiKey: apiKey,
            api: api,
            models: [{ id: modelId, name: modelId, contextWindow: 131072, maxTokens: 8192 }],
        };
        config.agents = config.agents || {};
        config.agents.defaults = config.agents.defaults || {};
        config.agents.defaults.model = { primary: providerName + '/' + modelId };
        console.log('AI Gateway model override: provider=' + providerName + ' model=' + modelId + ' via ' + baseUrl);
    }
}

// Telegram configuration
if (process.env.TELEGRAM_BOT_TOKEN) {
    const dmPolicy = process.env.TELEGRAM_DM_POLICY || 'pairing';
    config.channels.telegram = {
        botToken: process.env.TELEGRAM_BOT_TOKEN,
        enabled: true,
        dmPolicy: dmPolicy,
    };
    if (process.env.TELEGRAM_DM_ALLOW_FROM) {
        config.channels.telegram.allowFrom = process.env.TELEGRAM_DM_ALLOW_FROM.split(',');
    } else if (dmPolicy === 'open') {
        config.channels.telegram.allowFrom = ['*'];
    }
}

// Discord configuration
if (process.env.DISCORD_BOT_TOKEN) {
    const dmPolicy = process.env.DISCORD_DM_POLICY || 'pairing';
    const dm = { policy: dmPolicy };
    if (dmPolicy === 'open') {
        dm.allowFrom = ['*'];
    }
    config.channels.discord = {
        token: process.env.DISCORD_BOT_TOKEN,
        enabled: true,
        dm: dm,
    };
}

// Slack configuration
if (process.env.SLACK_BOT_TOKEN && process.env.SLACK_APP_TOKEN) {
    config.channels.slack = {
        botToken: process.env.SLACK_BOT_TOKEN,
        appToken: process.env.SLACK_APP_TOKEN,
        enabled: true,
    };
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log('Configuration patched successfully');
EOFPATCH

# ============================================================
# START GATEWAY
# ============================================================
echo "Starting OpenClaw Gateway..."
echo "Gateway will be available on port 18789"

rm -f /tmp/openclaw-gateway.lock 2>/dev/null || true
rm -f "$CONFIG_DIR/gateway.lock" 2>/dev/null || true

echo "Dev mode: ${OPENCLAW_DEV_MODE:-false}"

if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
    echo "Starting gateway with token auth..."
    exec openclaw gateway --port 18789 --verbose --allow-unconfigured --bind lan --token "$OPENCLAW_GATEWAY_TOKEN"
else
    echo "Starting gateway with device pairing (no token)..."
    exec openclaw gateway --port 18789 --verbose --allow-unconfigured --bind lan
fi
