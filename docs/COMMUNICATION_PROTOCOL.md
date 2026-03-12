# Communication Protocol

How the AI roles communicate through documents, with a human dispatcher
carrying context between sessions.

---

## Core Principle

**No direct communication between roles.** All coordination happens through:
1. **Documents** — Each role reads and writes specific files
2. **The Dispatcher** — A human who starts each Claude session and carries context

This isn't a limitation — it's a feature. Documents create an audit trail, prevent
miscommunication, and allow any session to pick up where the last one left off.

---

## Information Flow

```
                    ┌─────────────────────┐
                    │   Project Director   │
                    │   (strategic brain)  │
                    └──────┬──────────▲───┘
                           │          │
              writes       │          │ reads
           DIRECTIVES/     │          │ REPORTS/
                           │          │ DECISIONS.md
                           │          │ PROJECT_STATUS.md §2
                           │          │ ARCHITECTURE_VISION.md
                           ▼          │
                    ┌──────────────────┘──┐
                    │     Dispatcher      │
                    │   (human — you)     │
                    └──────┬──────────▲───┘
                           │          │
                           ▼          │
                    ┌─────────────────────┐
                    │ Development Director │
                    │  (technical brain)   │
                    └──────┬──────────▲───┘
                           │          │
              writes       │          │ reads
           TODO.md         │          │ TODO.md (checkboxes)
           DECISIONS.md    │          │ REPORTS/
           STATUS §2       │          │
                           ▼          │
                    ┌──────────────────┘──┐
                    │     Dispatcher      │
                    │   (human — you)     │
                    └──────┬──────────▲───┘
                           │          │
                           ▼          │
                    ┌─────────────────────┐
                    │  Development Team    │
                    │   (implementation)   │
                    └─────────────────────┘
                           │
              writes       │
           REPORTS/        │
           code + tests    │
           TODO checkboxes │


                    ┌─────────────────────┐
                    │  Doc Optimizer (DO)  │
                    │  (knowledge curator) │
                    └──────┬──────────▲───┘
                           │          │
              writes       │          │ reads ALL
           ARCHIVE/        │          │ documents
           OPT_LOG         │          │
                           ▼          │
                    ┌──────────────────┘──┐
                    │     Dispatcher      │
                    │   (invokes DO       │
                    │    periodically)    │
                    └────────────────────┘
```

---

## Document Ownership Matrix

| Document | PD Writes | DD Writes | Team Writes | DO Writes | Everyone Reads |
|----------|-----------|-----------|-------------|-----------|----------------|
| `DIRECTIVES/` | Yes | — | — | Archives COMPLETED | Yes |
| `PROJECT_STATUS.md` §1,3-9 | Yes | — | — | — | Yes |
| `PROJECT_STATUS.md` §2 | — | Yes | — | — | Yes |
| `DECISIONS.md` | — | Yes | — | Optimizes completed | Yes |
| `TODO.md` (text) | — | Yes | — | Optimizes completed | Yes |
| `TODO.md` (checkboxes) | — | — | Yes | — | Yes |
| `REPORTS/` | — | — | Yes | Archives completed | Yes |
| `ARCHITECTURE_VISION.md` | Co-approves changes | Proposes changes | — | — | Yes |
| `OPTIMIZATION_LOG.md` | — | — | — | Yes | Yes |
| `ARCHIVE_INDEX.md` | — | — | — | Yes | Yes |
| `ARCHIVE/` | — | — | — | Yes | Yes |
| Source code | — | — | Yes | — | — |

---

## Communication Patterns

### Pattern 1: PD Issues a Directive

**When:** PD identifies a strategic need (new feature, priority change, risk mitigation)

**Flow:**
1. PD creates `DIRECTIVES/DIRECTIVE_YYYY-MM-DD_topic.md` with status NEW
2. Dispatcher tells DD: "There's a new directive"
3. DD reads directive, creates TODO tasks, logs interpretation in DECISIONS.md
4. DD updates directive status to PROCESSED

**Documents touched:** DIRECTIVES/ (PD writes), TODO.md (DD writes), DECISIONS.md (DD writes)

### Pattern 2: Team Implements and Reports

**When:** Team has tasks assigned in TODO.md

**Flow:**
1. Team reads TODO.md and DECISIONS.md
2. Team implements, writes tests
3. Team creates `REPORTS/REPORT_YYYY-MM-DD_PHASE-N.md`
4. Team checks off completed tasks in TODO.md
5. Dispatcher tells DD: "There's a new report"

**Documents touched:** TODO.md checkboxes (Team), REPORTS/ (Team), source code (Team)

### Pattern 3: DD Reviews a Report

**When:** Team has submitted a report

**Flow:**
1. DD reads the report in REPORTS/
2. DD verifies acceptance criteria from TODO.md
3. DD writes review verdict in DECISIONS.md (ACCEPTED / NEEDS_FIXES / REJECTED)
4. If ACCEPTED: DD updates PROJECT_STATUS.md §2 (phase status)
5. Dispatcher tells Team the verdict (if NEEDS_FIXES) or tells PD the phase status

**Documents touched:** DECISIONS.md (DD writes), PROJECT_STATUS.md §2 (DD writes)

### Pattern 4: PD Updates Strategic Status

**When:** A phase is completed, or PD needs to make a strategic decision

**Flow:**
1. PD reads DECISIONS.md and REPORTS/ for context
2. PD updates PROJECT_STATUS.md §3-9 (completed work, risks, milestones, strategic log)
3. PD may issue a new directive based on current state

**Documents touched:** PROJECT_STATUS.md §3-9 (PD writes), potentially DIRECTIVES/ (PD writes)

### Pattern 5: Handling Disagreement

**When:** DD disagrees with a PD directive, or Team flags a concern

**Flow:**
1. The disagreeing role documents their reasoning in their output document
   - DD: writes in DECISIONS.md
   - Team: writes in report under "Open Questions"
2. Dispatcher carries both perspectives to the other role
3. Resolution follows the decision authority matrix:
   - Strategic matters → PD decides
   - Technical matters → DD decides
   - Boundary matters → Dispatcher arbitrates

**No role directly overrides another's documents.** Disagreements are resolved through the dispatcher.

### Pattern 6: Documentation Optimization Cycle

**When:** Multiple phases have completed, documents are growing large, or dispatcher notices sessions are getting expensive

**Flow:**
1. Dispatcher starts DO session: "Optimize documentation, archive completed phases"
2. DO scans all documents, reports current sizes and optimization opportunities
3. DO compresses completed phase content, archives old directives/reports
4. DO updates ARCHIVE_INDEX.md and OPTIMIZATION_LOG.md
5. DO reports token savings to dispatcher

**Documents touched:** OPTIMIZATION_LOG.md (DO writes), ARCHIVE_INDEX.md (DO writes), ARCHIVE/ (DO writes), TODO.md (DO optimizes completed phases), DECISIONS.md (DO optimizes completed phases), DIRECTIVES/ (DO archives COMPLETED), REPORTS/ (DO archives completed)

### Pattern 7: Archive Knowledge Retrieval

**When:** Any role needs information that may have been archived

**Flow:**
1. Role notes retrieval need in its output document (PD: strategic log, DD: DECISIONS.md, Team: report "Open Questions")
2. Dispatcher starts DO session with search query
3. DO searches ARCHIVE_INDEX.md and archive files
4. DO writes results to `ARCHIVE/RETRIEVAL_RESPONSE.md`
5. Dispatcher carries results to requesting role

**Documents touched:** ARCHIVE/RETRIEVAL_RESPONSE.md (DO writes), OPTIMIZATION_LOG.md (DO logs retrieval)

---

## The Dispatcher's Role

You (the human) are essential to this system. You:

1. **Start sessions** — Launch the right role when it's needed
2. **Carry context** — Tell each role what happened in previous sessions
3. **Sequence work** — Decide which role acts next
4. **Arbitrate** — Resolve boundary disputes between roles
5. **Override** — You can always override any role's decision

### What to Tell Each Role at Session Start

**When starting PD:**
- "DD completed review of Phase N — verdict: ACCEPTED"
- "Team reported a blocker: [description]"
- "New phase completed, please update status"

**When starting DD:**
- "PD issued a new directive about [topic]"
- "Team submitted a report for Phase N"
- "PD wants to reprioritize — read the latest directive"

**When starting Team:**
- "DD created tasks for Phase N in TODO.md"
- "DD reviewed your report — verdict: NEEDS_FIXES, see DECISIONS.md"
- "Green light to start Phase N"

**When starting DO:**
- "Phases 1-3 are completed and accepted. Optimize documentation and archive."
- "Team needs info about the Phase 1 storage decision. Search the archive."
- "Documents are getting large — please do a cleanup pass."

---

## Session Continuity

Each role starts every session by reading its core documents. This means:

- **No session memory is needed** — Everything important is in documents
- **Any Claude instance can continue** — New session, different model, doesn't matter
- **Crash recovery is automatic** — If a session breaks, start a new one and it picks up from documents

The strategic log (PROJECT_STATUS.md §8) and technical decisions (DECISIONS.md) serve as **permanent memory** across sessions.

---

## Common Mistakes to Avoid

| Mistake | Why It's Bad | What to Do Instead |
|---------|-------------|-------------------|
| PD writes TODO tasks | Crosses role boundaries, bypasses DD's technical judgment | PD issues a directive; DD creates tasks |
| DD modifies strategic sections of PROJECT_STATUS.md | Undermines PD's authority, causes conflicts | DD updates §2 only; PD updates §3-9 |
| Team modifies TODO text | Backlog becomes unreliable | Team checks boxes only; flags issues in reports |
| Skipping reports | DD can't review, PD can't track | Every implementation session ends with a report |
| Direct role-to-role communication | Breaks the audit trail | Always go through documents + dispatcher |
| Roles reading files they don't own | Fine — reading is always OK | Reading is encouraged! Only writing is restricted |
| DO modifies active phase content | Disrupts ongoing work | DO only optimizes COMPLETED + ACCEPTED phase content |
| DO deletes instead of archiving | Permanent knowledge loss | Always archive, never delete |
| Roles bypass dispatcher for archive retrieval | Breaks audit trail | Request through documents + dispatcher |
