# AI Team Framework

A file-based framework for managing software projects with multiple AI roles.
Three specialized Claude sessions — **Project Director**, **Development Director**,
and **Development Team** — collaborate through markdown documents, with a human
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
                          ▲
                          │
                    You (dispatcher)
              start sessions, carry context
```

Each role:
- Reads specific documents at session start (its "startup protocol")
- Does its job (issue directives / create tasks / implement code)
- Writes results to specific documents
- Has NO memory between sessions — documents carry all state

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

The Wizard asks about your project (name, tech stack, conventions, phases) and
generates a complete `docs/TEAM/` directory with all role definitions and state files.

### 3. Start your first cycle

```bash
# Start a Project Director session
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
│   └── REPORTS/                     # Team's implementation reports
└── start_role.sh                    # Launcher script
```

---

## Key Concepts

### Document Ownership

Each document has clear ownership — who writes what:

| Document | PD | DD | Team |
|----------|-----|-----|------|
| DIRECTIVES/ | writes | reads | reads |
| PROJECT_STATUS.md §2 | reads | **writes** | reads |
| PROJECT_STATUS.md §3-9 | **writes** | reads | reads |
| DECISIONS.md | reads | **writes** | reads |
| TODO.md (text) | reads | **writes** | reads |
| TODO.md (checkboxes) | reads | reads | **writes** |
| REPORTS/ | reads | reads | **writes** |
| Source code | — | — | **writes** |

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
│   └── REPORT_TEMPLATE.md
├── scripts/
│   └── start_role.sh                    # Role launcher script
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

## Origin

This framework was extracted from [ai-software-swarm](https://github.com/dusankrstic-cpu/ai-software-swarm),
where it emerged organically during development. Three AI roles completed 7 phases
(210 tests) in a single day with full traceability. The framework proved effective
enough to extract into a standalone, project-agnostic tool.

---

## License

MIT
