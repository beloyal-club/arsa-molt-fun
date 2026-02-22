---
name: bmad-method
description: AI-driven agile development using BMAD methodology. Specialized agents (PM, Architect, Dev, UX, SM) guide projects through Analysis → Planning → Solutioning → Implementation. Use for structured feature development, architecture decisions, and sprint management. Integrates with Discord for workflow triggers.
---

# BMAD Method for OpenClaw

Implement the **Breakthrough Method of Agile AI Driven Development** within OpenClaw using specialized agent personas and structured workflows.

## Overview

BMAD provides:
- **Specialized Agents** — PM, Architect, Developer, UX Designer, Scrum Master
- **4 Phases** — Analysis → Planning → Solutioning → Implementation
- **3 Tracks** — Quick Flow (bugs/simple), BMad Method (products), Enterprise (complex)
- **Guided Workflows** — Structured processes for each development task

## OpenClaw Integration Architecture

### Agent Personas via sessions_spawn

Each BMAD agent is implemented as a sub-agent with a specialized system prompt:

```
sessions_spawn(
  task="[workflow task]",
  agentId="bmad-pm",  // or bmad-architect, bmad-dev, etc.
  label="bmad-pm-session"
)
```

### Workflow Triggers via Discord

Discord commands map to BMAD workflows:

| Discord Command | Workflow | Agent | Output |
|-----------------|----------|-------|--------|
| `/bmad-help` | Get guidance | Any | Next steps |
| `/bmad-brief` | Create product brief | Analyst | `brief.md` |
| `/bmad-prd` | Create PRD | PM | `PRD.md` |
| `/bmad-arch` | Create architecture | Architect | `architecture.md` |
| `/bmad-stories` | Create epics/stories | PM | `epics/*.md` |
| `/bmad-sprint` | Sprint planning | SM | `sprint-status.yaml` |
| `/bmad-dev` | Implement story | Dev | Code changes |
| `/bmad-review` | Code review | Dev | Review notes |

### Artifact Storage

All BMAD outputs go to workspace:

```
/root/.openclaw/workspace/
├── bmad-output/
│   ├── planning/
│   │   ├── brief.md
│   │   ├── PRD.md
│   │   ├── architecture.md
│   │   └── epics/
│   │       ├── epic-1.md
│   │       └── epic-2.md
│   ├── implementation/
│   │   ├── sprint-status.yaml
│   │   └── stories/
│   └── project-context.md
```

## Agent Personas

### PM (Product Manager)
**Role:** Requirements, prioritization, stakeholder alignment
**Workflows:** create-prd, create-epics-and-stories
**Persona:** Strategic thinker, user-focused, balances scope with feasibility

### Architect
**Role:** Technical decisions, system design, integration patterns
**Workflows:** create-architecture, check-implementation-readiness
**Persona:** Big-picture thinker, pragmatic, considers scale and maintainability

### Developer (Dev)
**Role:** Implementation, code quality, technical execution
**Workflows:** dev-story, code-review
**Persona:** Detail-oriented, clean code advocate, tests-first mindset

### UX Designer
**Role:** User experience, interface design, usability
**Workflows:** create-ux-design
**Persona:** User empathy, simplicity advocate, accessibility-aware

### Scrum Master (SM)
**Role:** Sprint management, blockers, team coordination
**Workflows:** sprint-planning, create-story, retrospective
**Persona:** Process facilitator, removes obstacles, tracks velocity

### Analyst
**Role:** Research, brainstorming, discovery
**Workflows:** brainstorming, research, create-product-brief
**Persona:** Curious, thorough, synthesizes information

## Implementation Plan

### Phase 1: Agent Personas (Core)

Create persona files in `bmad-method/personas/`:

```yaml
# personas/pm.yaml
name: "PM Agent"
role: "Product Manager"
identity: |
  You are a senior Product Manager with 10+ years experience 
  shipping products at scale. You think in terms of user value,
  business outcomes, and technical feasibility.
communication_style: |
  Clear, structured, asks clarifying questions.
  Uses bullet points and tables for clarity.
  Always ties features back to user problems.
principles:
  - "Start with the user problem, not the solution"
  - "Scope ruthlessly — MVP first"
  - "Requirements should be testable"
  - "Involve engineering early"
```

### Phase 2: Workflow Templates

Create workflow prompts in `bmad-method/workflows/`:

```yaml
# workflows/create-prd.yaml
name: "Create PRD"
agent: pm
inputs:
  - brief.md (optional)
  - user research (optional)
outputs:
  - PRD.md
steps:
  1. Understand the problem space
  2. Define user personas and journeys
  3. List functional requirements
  4. List non-functional requirements
  5. Define success metrics
  6. Identify risks and dependencies
template: |
  # Product Requirements Document
  
  ## Problem Statement
  [What problem are we solving?]
  
  ## User Personas
  [Who are we building for?]
  
  ## Requirements
  ### Functional
  ### Non-Functional
  
  ## Success Metrics
  
  ## Risks & Dependencies
```

### Phase 3: Discord Integration

Map Discord slash commands to OpenClaw actions:

```javascript
// Discord bot command handler
switch (command) {
  case 'bmad-help':
    // Send to main session for guidance
    sessions_send({ message: "/bmad-help " + userQuery });
    break;
  case 'bmad-prd':
    // Spawn PM agent session
    sessions_spawn({
      task: "Create a PRD based on: " + userInput,
      agentId: "bmad-pm",
      label: "prd-" + timestamp
    });
    break;
  // ...
}
```

### Phase 4: Party Mode

For complex decisions, spawn multiple agents:

```
1. Spawn PM agent → gathers requirements
2. Spawn Architect agent → reviews technical feasibility
3. Spawn Dev agent → estimates effort
4. Main session synthesizes all inputs
```

## Quick Start

### For Simple Tasks (Quick Flow)

1. User in Discord: `/bmad-dev fix the login bug`
2. Dev agent spawns, analyzes issue, proposes fix
3. Results posted back to Discord

### For Features (BMad Method)

1. `/bmad-brief` → Analyst creates product brief
2. `/bmad-prd` → PM creates requirements
3. `/bmad-arch` → Architect designs solution
4. `/bmad-stories` → PM breaks into epics
5. `/bmad-sprint` → SM plans sprint
6. `/bmad-dev [story-id]` → Dev implements

## Next Steps

1. **Create persona YAML files** for each agent
2. **Create workflow templates** for each process
3. **Set up Discord channel** with slash commands
4. **Configure OpenClaw** to handle Discord triggers
5. **Test with a real feature** end-to-end

## References

- [BMAD Method GitHub](https://github.com/bmad-code-org/BMAD-METHOD)
- [BMAD Docs](https://docs.bmad-method.org)
- [OpenClaw sessions_spawn](https://docs.openclaw.ai)
