# AI Team Framework

A file-based framework for managing software projects with multiple AI roles.
Built for **Claude Code** (Anthropic's CLI for Claude). Specialized Claude sessions —
**Project Director**, **Development Director**, **Development Team**, and optionally
**Documentation Optimizer** — collaborate through markdown documents, with a human
dispatcher coordinating between them.

No server, no database, just markdown files and conventions.

---

## How It Works

```
Project Director        Development Director        Development Team
(strategic brain)       (technical brain)            (implementation)
     │                        │                           │
     │ writes DIRECTIVES/     │ writes TODO.md            │ writes code
     │                        │ writes DECISIONS.md       │ writes REPORTS/
     │                        │                           │ checks TODO boxes
     ▼                        ▼                           ▼
 ┌──────────────────────────────────────────────────────────┐
 │              Documents (the source of truth)             │
 └──────────────────────────────────────────────────────────┘
                          ▲           │
                          │           │ optimizes + archives
                    You (dispatcher)  ▼
              start sessions,   Doc Optimizer (optional)
              carry context     (knowledge curator)
```

Each role:
- Reads specific documents at session start (its "startup protocol")
- Does its job (issue directives / create tasks / implement code)
- Writes results to specific documents
- Has NO memory between sessions — documents carry all state

---

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic's CLI for Claude) installed and available as `claude`

---

## Quick Start

### 1. Clone the framework

```bash
git clone https://github.com/dusankrstic-cpu/ai-team-framework.git
```

### 2. Run the Wizard in your project

```bash
cd /path/to/your-project
claude "$(cat /path/to/ai-team-framework/wizard/WIZARD.md)"
```

Or use the launcher script:

```bash
cd /path/to/your-project
/path/to/ai-team-framework/scripts/start_role.sh wizard
```

The Wizard asks about your project (name, tech stack, conventions, phases) and
generates a complete `docs/TEAM/` directory with all role definitions and state files,
including a `start_role.sh` launcher script in your project root.

### 3. Start your first cycle

Use the generated launcher script:

```bash
./start_role.sh pd     # Start a Project Director session
./start_role.sh dd     # Start a Development Director session
./start_role.sh team   # Start a Development Team session
./start_role.sh doc    # Start a Documentation Optimizer session (if enabled)
```

Or start manually:

```bash
claude
# Tell it: "Read docs/TEAM/PROJECT_DIRECTOR.md and follow the startup protocol"
```

---

## The Workflow Cycle

```
1. PD session   → Reviews state, issues directive
2. DD session   → Reads directive, creates TODO tasks
3. Team session → Implements, writes report
4. DD session   → Reviews report, issues verdict (ACCEPTED / NEEDS_FIXES)
5. PD session   → Updates status, decides next steps
   └── Repeat
*. DO session   → (periodically) Optimizes docs, archives completed work
```

You (the dispatcher) start each session and tell the role what happened since last
time. Each role reads its documents and picks up where the previous session left off.

---

## What Gets Generated

After the Wizard runs, your project has:

```
your-project/
├── docs/TEAM/
│   ├── PROJECT_DIRECTOR.md          # PD role definition
│   ├── DEVELOPMENT_DIRECTOR.md      # DD role definition
│   ├── DEVELOPMENT_TEAM.md          # Team role definition
│   ├── PROJECT_STATUS.md            # Shared state (PD + DD sections)
│   ├── DECISIONS.md                 # DD's permanent memory
│   ├── TODO.md                      # Task backlog
│   ├── ARCHITECTURE_VISION.md       # Technical north star
│   ├── DIRECTIVE_TEMPLATE.md        # Format reference
│   ├── REPORT_TEMPLATE.md           # Format reference
│   ├── DIRECTIVES/                  # PD's strategic directives
│   ├── REPORTS/                     # Team's implementation reports
│   ├── DOC_OPTIMIZER.md             # DO role definition (if enabled)
│   ├── OPTIMIZATION_LOG.md          # DO's permanent memory (if enabled)
│   ├── ARCHIVE_INDEX.md             # Archive master index (if enabled)
│   └── ARCHIVE/                     # Archived documents (if enabled)
└── start_role.sh                    # Launcher script
```

---

## Key Concepts

### Document Ownership

Each document has clear ownership — who writes what:

| Document | PD | DD | Team | DO |
|----------|-----|-----|------|-----|
| DIRECTIVES/ | writes | reads | reads | archives completed |
| PROJECT_STATUS.md §2 | reads | **writes** | reads | — |
| PROJECT_STATUS.md §1,3-9 | **writes** | reads | reads | — |
| DECISIONS.md | reads | **writes** | reads | optimizes completed |
| TODO.md (text) | reads | **writes** | reads | optimizes completed |
| TODO.md (checkboxes) | reads | reads | **writes** | — |
| REPORTS/ | reads | reads | **writes** | archives completed |
| OPTIMIZATION_LOG.md | reads | reads | — | **writes** |
| ARCHIVE/ | reads | reads | reads | **writes** |
| Source code | — | — | **writes** | — |

### Status Lifecycle

**Directives:** `NEW` → `PROCESSED` → `COMPLETED`

**Reports:** `COMPLETED` / `PARTIAL` / `BLOCKED`

**Review verdicts:** `ACCEPTED` / `NEEDS_FIXES` / `REJECTED`

**Phases:** `NOT_STARTED` / `IN_PROGRESS` / `COMPLETED` / `BLOCKED`

### Decision Authority

| Decision Type | PD | DD | Team |
|--------------|-----|-----|------|
| Strategic (priorities, scope) | **Final** | Input | Proposal |
| Technical (architecture, patterns) | Input | **Final** | Input |
| Trivial (variable names) | — | — | **Final** |
| Boundary (big scope changes) | Strategic | Technical | **Dispatcher decides** |

---

## Framework Structure

```
ai-team-framework/
├── README.md                            # This file
├── LICENSE                              # MIT
├── .gitignore
├── wizard/
│   ├── WIZARD.md                        # Wizard system prompt
│   └── WIZARD_CHECKLIST.md              # Generation completeness checklist
├── templates/                           # Annotated reference templates
│   ├── PROJECT_DIRECTOR.md
│   ├── DEVELOPMENT_DIRECTOR.md
│   ├── DEVELOPMENT_TEAM.md
│   ├── PROJECT_STATUS.md
│   ├── DECISIONS.md
│   ├── TODO.md
│   ├── ARCHITECTURE_VISION.md
│   ├── DIRECTIVE_TEMPLATE.md
│   ├── REPORT_TEMPLATE.md
│   ├── DOC_OPTIMIZER.md                 # DO role definition template
│   ├── OPTIMIZATION_LOG.md              # Optimization log template
│   └── ARCHIVE_INDEX.md                 # Archive index template
├── scripts/
│   ├── start_role.sh                    # Role launcher (pd|dd|team|doc|wizard|help)
│   └── update_project.sh               # Project updater (framework version upgrades)
├── update/
│   └── UPDATE_PROMPT.md                 # Update agent instructions
└── docs/
    ├── GUIDE.md                         # Detailed user guide
    ├── ROLES_EXPLAINED.md               # Deep dive into each role
    ├── COMMUNICATION_PROTOCOL.md        # How roles talk through documents
    └── EXAMPLES.md                      # Full session cycle walkthrough
```

---

## Documentation

| Document | What You'll Learn |
|----------|------------------|
| [User Guide](docs/GUIDE.md) | Setup, workflow, tips, troubleshooting |
| [Roles Explained](docs/ROLES_EXPLAINED.md) | What each role does and why |
| [Communication Protocol](docs/COMMUNICATION_PROTOCOL.md) | How information flows between roles |
| [Examples](docs/EXAMPLES.md) | Complete walkthrough of a real cycle |

---

## Example

The `docs/TEAM/` directory in this repo contains real files from the project where
this framework was originally developed ([ai-software-swarm](https://github.com/dusankrstic-cpu/ai-software-swarm)).
You can browse them to see what the Wizard generates in practice.

---

## Updating an Existing Project

When you pull a newer version of the framework, update your project's team files:

```bash
cd /path/to/ai-team-framework
git pull

# Update your project
./scripts/update_project.sh /path/to/your-project
```

The update script:
- Shows a disclaimer (your project is in active use — proceed at your own risk)
- Creates a full backup before making changes
- Uses Claude to intelligently regenerate role definitions with your project's customizations
- Preserves all stateful files (PROJECT_STATUS.md, DECISIONS.md, TODO.md, etc.)
- Reports what was changed and how to rollback

---

## Origin

This framework was extracted from [ai-software-swarm](https://github.com/dusankrstic-cpu/ai-software-swarm),
where it emerged organically during development. Three AI roles completed 7 phases
(210 tests) in a single day with full traceability. The framework proved effective
enough to extract into a standalone, project-agnostic tool.

---

## License

MIT
