---
name: code-orchestrator
description: Orchestrate coding tasks via sandboxed sub-agents. Use when code changes are needed - spawns agents that work on feature branches with CI validation.
---

# Code Orchestrator

Delegate coding tasks to sub-agents that work in isolation with CI validation.

## Pattern

```
Orchestrator (you)
    │
    ├──► spawn "coding-agent" with task
    │         └──► works on feature branch
    │         └──► pushes code
    │         └──► CI validates
    │
    └──► monitor progress
              └──► review results
              └──► approve/merge or iterate
```

## Workflow

### 1. Create Task Spec

Before spawning, write a clear spec:

```markdown
## Task: [short name]
**Branch:** feature/[name]
**Goal:** [what should be achieved]
**Files to modify:**
- path/to/file.ts - [what changes]
**Acceptance criteria:**
- [ ] Tests pass
- [ ] Type check passes
- [ ] Build succeeds
```

### 2. Spawn Coding Agent

```
sessions_spawn({
  task: `
    You are a coding agent. Your task:
    
    1. cd /root/arsa-molt-fun
    2. git checkout feature/[name] (or create if needed)
    3. Implement: [task description]
    4. Run: npm test && npm run typecheck
    5. If tests pass: git push
    6. Report results
    
    Spec: [paste spec or file path]
  `,
  label: "coding-[task-name]",
  runTimeoutSeconds: 300
})
```

### 3. Monitor & Validate

After agent completes:
1. Check GitHub Actions for CI results
2. Review the diff: `git diff main..feature/[name]`
3. If issues: spawn another agent to fix, or provide feedback

### 4. Merge or Iterate

If validated:
```bash
cd /root/arsa-molt-fun
git checkout main
git merge feature/[name]
git push
```

## Example: Implementing Secrets Store

```
sessions_spawn({
  task: `
    You are a coding agent implementing Cloudflare Secrets Store.
    
    1. cd /root/arsa-molt-fun
    2. git checkout feature/secrets-store-codemode
    3. Read docs/specs/secrets-store-codemode.md
    4. Implement Part 1 (Secrets Store) only:
       - Add binding to wrangler.jsonc
       - Add /api/internal/secrets/:name endpoint
       - Add types to src/types.ts
    5. Run: npm test && npm run typecheck
    6. If pass: git add . && git commit -m "feat: add Secrets Store integration" && git push
    7. Report what you did and any issues
  `,
  label: "coding-secrets-store",
  runTimeoutSeconds: 300
})
```

## Safety Rules

1. **Never merge without CI passing**
2. **Never push directly to main** - always feature branches
3. **Review diffs before merging**
4. **One task per agent** - keep scope bounded

## CI Integration

The `sandbox-test.yml` workflow runs on all `feature/**` branches:
- Type check
- Unit tests
- Build verification

Check results at: https://github.com/beloyal-club/arsa-molt-fun/actions
