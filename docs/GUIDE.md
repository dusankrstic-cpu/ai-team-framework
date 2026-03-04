# AI Team Framework — User Guide

A step-by-step guide to using the AI Team Framework for your projects.

---

## Prerequisites

- **Claude Code** CLI installed (`claude` command available)
- **A project** — existing or new — that you want to build with AI assistance
- **This framework** — cloned or downloaded somewhere accessible

---

## Quick Start (5 Minutes)

### Step 1: Clone the Framework

```bash
git clone https://github.com/dusankrstic-cpu/ai-team-framework.git
```

### Step 2: Run the Wizard

In your project directory:

```bash
cd /path/to/your-project
claude "$(cat /path/to/ai-team-framework/wizard/WIZARD.md)"
```

The Wizard will ask you about your project in 4 phases, then generate all team files
in `docs/TEAM/`.

### Step 3: Start Your First Cycle

Use the generated launcher script:

```bash
./start_role.sh pd     # Start a Project Director session
```

Or start manually:

```bash
claude
# Tell it: "Read docs/TEAM/PROJECT_DIRECTOR.md and follow the startup protocol"
```

The PD will review the initial state and issue the first directive.

---

## Detailed Setup

### What the Wizard Generates

After the Wizard runs, your project will have:

```
your-project/
├── docs/
│   └── TEAM/
│       ├── PROJECT_DIRECTOR.md       # PD role definition
│       ├── DEVELOPMENT_DIRECTOR.md   # DD role definition
│       ├── DEVELOPMENT_TEAM.md       # Team role definition
│       ├── PROJECT_STATUS.md         # Shared state file
│       ├── DECISIONS.md              # DD's technical memory
│       ├── TODO.md                   # Task backlog
│       ├── ARCHITECTURE_VISION.md    # Technical vision
│       ├── DIRECTIVE_TEMPLATE.md     # Format reference
│       ├── REPORT_TEMPLATE.md        # Format reference
│       ├── DIRECTIVES/               # PD's directives (empty)
│       └── REPORTS/                  # Team's reports (empty)
└── start_role.sh                     # Launcher script
```

All files are customized for your project — your name, your tech stack, your
conventions, your phases.

### Using the Launcher Script

```bash
./start_role.sh pd      # Start Project Director
./start_role.sh dd      # Start Development Director
./start_role.sh team    # Start Development Team
```

### Manual Session Start

If you prefer not to use the launcher script:

```bash
claude
# Then: "Read docs/TEAM/PROJECT_DIRECTOR.md and follow the startup protocol"
```

---

## The Workflow Cycle

### Standard Cycle

Every development cycle follows this pattern:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  1. PD Session                                      │
│     → Reviews current state                         │
│     → Issues directive or updates status             │
│                                                     │
│  2. DD Session                                      │
│     → Reads new directive                           │
│     → Creates TODO tasks for next phase             │
│     → Logs decisions in DECISIONS.md                │
│                                                     │
│  3. Team Session                                    │
│     → Reads TODO.md and DECISIONS.md                │
│     → Implements the assigned phase                 │
│     → Writes report in REPORTS/                     │
│     → Checks off TODO items                         │
│                                                     │
│  4. DD Session (Review)                             │
│     → Reads the report                              │
│     → Verifies acceptance criteria                  │
│     → Issues verdict: ACCEPTED / NEEDS_FIXES        │
│     → Updates phase status in PROJECT_STATUS.md §2  │
│                                                     │
│  5. PD Session (if needed)                          │
│     → Updates PROJECT_STATUS.md §3-9                │
│     → Decides next direction                        │
│     → Issues new directive or closes phase          │
│                                                     │
│  └─── Repeat ─────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### Your Role as Dispatcher

Between sessions, you:

1. **Tell the next role what happened.** Each session starts fresh — the role reads
   its documents, but you provide the human context.

2. **Decide which role acts next.** Follow the standard cycle, or adapt as needed.

3. **Resolve disputes.** If PD and DD disagree, you decide. If Team raises a concern
   that can't wait for a review, you route it.

### What to Say When Starting Each Session

**Starting PD:**
> "Read docs/TEAM/PROJECT_DIRECTOR.md. The DD just accepted Phase 2. Update status
> and decide what's next."

**Starting DD:**
> "Read docs/TEAM/DEVELOPMENT_DIRECTOR.md. There's a new directive about
> authentication. Create TODO tasks."

**Starting Team:**
> "Read docs/TEAM/DEVELOPMENT_TEAM.md. Phase 3 tasks are ready in TODO.md. Green
> light to start."

---

## Tips for Effective Use

### 1. Keep Sessions Focused

Each session should do one thing:
- PD: Issue one directive or update status
- DD: Process one directive or review one report
- Team: Implement one phase

Don't ask a single session to do multiple roles' work.

### 2. Trust the Documents

The documents ARE the project state. If it's not in the documents, it didn't happen.
This means:
- Every decision gets logged
- Every implementation gets reported
- Every directive has a paper trail

### 3. The DD's DECISIONS.md is Critical

This file is the DD's memory across sessions. A well-maintained DECISIONS.md means:
- New DD sessions instantly understand past technical choices
- Guidelines accumulate and improve over time
- Review criteria become more precise

### 4. Reports Should Be Honest

The Team should report PARTIAL or BLOCKED when that's the truth. Reporting COMPLETED
when criteria aren't met just delays discovery and makes the DD's job harder.

### 5. Adapt the Process to Your Needs

The framework is a starting point. Common adaptations:

| Situation | Adaptation |
|-----------|-----------|
| Small project, clear direction | Skip PD sessions, have DD drive |
| Solo developer | Combine PD + DD into one session |
| Very large project | Add sub-teams, each with their own TODO section |
| Exploratory/research phase | Relax review strictness, allow more autonomy |
| Critical production system | Tighten review strictness, require explicit acceptance |

### 6. Phase 0 Matters

Don't skip Phase 0 (Setup and Framework). It verifies that:
- The project structure exists
- Tooling works (test runner, etc.)
- Everyone can read their role files
- The team is aligned on conventions

A solid Phase 0 prevents "works on my machine" problems later.

---

## Troubleshooting

### "Claude doesn't follow the role definition"

Make sure you're telling Claude to read the role file at the start of the session.
Claude won't automatically know about it.

```
"Read docs/TEAM/PROJECT_DIRECTOR.md and follow the startup protocol."
```

### "The roles are stepping on each other"

Check the document ownership matrix in COMMUNICATION_PROTOCOL.md. Common issues:
- PD writing TODO tasks (should issue a directive instead)
- DD modifying PROJECT_STATUS.md §3-9 (DD only writes §2)
- Team modifying TODO text (Team only checks boxes)

### "Sessions don't remember previous work"

That's by design. Sessions are stateless — documents carry the state. Make sure:
- The role reads its startup files (listed in its startup protocol)
- You tell the role what happened in the previous session
- Decisions are logged in the appropriate document

### "The process feels slow"

You can speed things up by:
- Combining PD + DD into one session for small projects
- Batching reviews (DD reviews multiple reports at once)
- Giving the DD higher autonomy (fewer PD check-ins needed)
- Having the Team handle multiple phases per session

### "A phase is stuck"

1. Check REPORTS/ for the latest status (PARTIAL? BLOCKED?)
2. Check DECISIONS.md for the latest review verdict
3. If NEEDS_FIXES: re-read the specific issues and start a new Team session
4. If BLOCKED: identify the blocker and start a PD or DD session to resolve it

---

## Directory Layout Reference

```
docs/TEAM/
├── PROJECT_DIRECTOR.md           # Who the PD is, what they do
├── DEVELOPMENT_DIRECTOR.md       # Who the DD is, what they do
├── DEVELOPMENT_TEAM.md           # Who the Team is, what they do
├── PROJECT_STATUS.md             # Shared state (sections owned by PD + DD)
├── DECISIONS.md                  # DD's permanent memory
├── TODO.md                       # Task backlog (DD manages)
├── ARCHITECTURE_VISION.md        # Technical north star
├── DIRECTIVE_TEMPLATE.md         # Format reference for directives
├── REPORT_TEMPLATE.md            # Format reference for reports
├── DIRECTIVES/
│   ├── DIRECTIVE_2026-03-01_auth.md
│   └── DIRECTIVE_2026-03-05_api.md
└── REPORTS/
    ├── REPORT_2026-03-02_PHASE-1.md
    └── REPORT_2026-03-04_PHASE-2.md
```
