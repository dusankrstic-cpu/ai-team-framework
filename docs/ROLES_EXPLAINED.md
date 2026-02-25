# Roles Explained

A deep dive into each role in the AI Team Framework — what they do, why they exist,
and how they interact.

---

## Why Three Roles?

A single AI session trying to be strategist, architect, and implementer simultaneously
tends to lose focus. It optimizes for the immediate coding task and forgets the bigger
picture. Or it over-plans and never ships.

Three specialized roles solve this:

| Problem | Solution |
|---------|---------|
| "I forgot why we're building this" | Project Director holds the vision |
| "The code doesn't follow the architecture" | Development Director enforces consistency |
| "Nobody reviewed this before merging" | DD reviews every implementation report |
| "We lost track of what's done" | PD maintains strategic status |
| "Sessions don't remember previous decisions" | DECISIONS.md is permanent memory |

---

## The Project Director

### Identity

The strategic brain. Thinks in milestones, risks, and priorities — never in code.

### Core Loop

```
Read current state
  → Identify what needs to happen next
  → Issue directive (or update status)
  → Wait for DD/Team to execute
  → Review results
  → Repeat
```

### What "Good PD Work" Looks Like

- Clear directives with strategic rationale
- Strategic log entries that explain *why*, not just *what*
- Proactive risk identification
- Phase completion tracked accurately
- Scope managed explicitly (what's in, what's out, what's deferred)

### When to Start a PD Session

- At project start (initial directives)
- After a phase completes (status update + next directive)
- When priorities change (scope/priority directive)
- When blockers arise (strategic decision needed)
- Periodically for strategic review

### PD Writes To

| Document | Sections | Purpose |
|----------|----------|---------|
| `DIRECTIVES/` | Full files | Strategic direction |
| `PROJECT_STATUS.md` | §1, §3-9 | State tracking + strategic log |

### PD Reads

Everything. PD has read access to all documents for full visibility.

---

## The Development Director

### Identity

The technical brain. Bridges strategy and implementation. Translates the PD's *what*
into the Team's *how*. Quality gatekeeper.

### Core Loop

```
Read directives and current state
  → Create/update TODO tasks
  → Wait for Team to implement
  → Review report against acceptance criteria
  → Issue verdict (ACCEPTED / NEEDS_FIXES / REJECTED)
  → Update phase status
  → Log decision in DECISIONS.md
  → Repeat
```

### What "Good DD Work" Looks Like

- TODO tasks that are specific, testable, and unambiguous
- Reviews that are thorough but fair
- Acceptance criteria that are objectively verifiable
- DECISIONS.md entries that future sessions can learn from
- Phase dependencies mapped correctly
- Technical decisions that balance pragmatism and quality

### When to Start a DD Session

- After PD issues a new directive (create TODO tasks)
- After Team submits a report (review it)
- When technical decisions are needed (log in DECISIONS.md)
- When phase planning is needed (update TODO.md)

### DD Writes To

| Document | Sections | Purpose |
|----------|----------|---------|
| `TODO.md` | Full file | Task backlog management |
| `DECISIONS.md` | Full file | Technical memory |
| `PROJECT_STATUS.md` | §2 only | Phase table and dependency graph |

### DD Reads

Everything except source code (the DD doesn't write or review individual code files —
they review at the report/criteria level).

### The DD's Secret Weapon: DECISIONS.md

DECISIONS.md is the DD's **permanent memory**. Every new DD session starts by reading
it. This means:

- Technical decisions persist across sessions
- Review verdicts are on record
- Guidelines accumulate over time
- The DD gets smarter with every session

A DD session without DECISIONS.md entries is a wasted session.

---

## The Development Team

### Identity

The hands. Writes every line of code, every test, every report. Follows direction
faithfully and raises concerns through proper channels.

### Core Loop

```
Read TODO.md (work orders)
  → Read DECISIONS.md (technical guidelines)
  → Implement assigned phase
  → Run tests
  → Write report
  → Check off TODO items
  → Submit for review
  → If NEEDS_FIXES: address feedback, resubmit
```

### What "Good Team Work" Looks Like

- Clean code following all conventions from DEVELOPMENT_TEAM.md
- All acceptance criteria met (or clearly documented why not)
- All tests passing (existing + new)
- Honest reports (PARTIAL is OK — lying about COMPLETED is not)
- Questions raised constructively in reports (not silently worked around)

### When to Start a Team Session

- After DD creates TODO tasks for a phase
- After DD issues NEEDS_FIXES verdict (address feedback)
- When implementation is needed

### Team Writes To

| Document | Sections | Purpose |
|----------|----------|---------|
| `REPORTS/` | Full files | Implementation reports |
| `TODO.md` | Checkboxes only | Progress tracking |
| Source code | Full files | Implementation |
| Test files | Full files | Testing |

### Team Reads

| Document | Purpose |
|----------|---------|
| `DEVELOPMENT_TEAM.md` | Role definition and conventions |
| `TODO.md` | Work orders |
| `DECISIONS.md` | Technical guidelines |
| `ARCHITECTURE_VISION.md` | Architectural context |
| `REPORTS/` | Previous reports for continuity |

---

## The Dispatcher (You)

### Identity

The human who runs the show. You're not a role — you're the orchestrator.

### Your Responsibilities

1. **Start the right session at the right time**
   - Don't run PD when there's nothing to decide
   - Don't run Team when there are no tasks
   - Follow the workflow cycle (see below)

2. **Carry context between sessions**
   - Each role starts fresh — tell them what happened
   - "DD reviewed Phase 2 — ACCEPTED" is more useful than "check the files"

3. **Resolve boundary disputes**
   - PD and DD disagree? You decide.
   - Team raises a concern that crosses role boundaries? You route it.

4. **Stay out of the way (mostly)**
   - Let PD set strategy, DD make technical calls, Team implement
   - Override when your judgment says they're wrong
   - But trust the process — it works

### Standard Workflow Cycle

```
1. PD session  → Reviews state, issues directive
2. DD session  → Reads directive, creates TODO tasks
3. Team session → Implements, writes report
4. DD session  → Reviews report, issues verdict
   └─ If NEEDS_FIXES → back to step 3
5. PD session  → Updates status, next directive
   └─ Repeat from step 2 (or 1 if new direction needed)
```

### Accelerated Workflow

For experienced users, you can skip some steps:

- **Skip PD for routine phases** — If the direction is clear, go straight from DD to Team
- **Batch reviews** — Have DD review multiple reports in one session
- **Merge DD + PD** — For small projects, one person can play both strategic and technical roles (but still maintain separate documents)

---

## Role Boundaries — Quick Reference

| Action | PD | DD | Team |
|--------|-----|-----|------|
| Set project vision | **Yes** | No | No |
| Issue directives | **Yes** | No | No |
| Create TODO tasks | No | **Yes** | No |
| Make technical decisions | No | **Yes** | Propose |
| Write code | No | No | **Yes** |
| Write tests | No | No | **Yes** |
| Review implementations | No | **Yes** | No |
| Update phase status table | No | **Yes** | No |
| Update strategic log | **Yes** | No | No |
| Check TODO boxes | No | No | **Yes** |
| Write reports | No | No | **Yes** |
| Modify ARCHITECTURE_VISION | Co-approve | Propose | No |
