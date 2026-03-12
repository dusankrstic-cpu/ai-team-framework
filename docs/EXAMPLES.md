# Examples — Full Session Cycle Walkthrough

A concrete example showing how the AI Team Framework works in practice using
**Claude Code CLI**. We'll follow a fictional project through its first complete
cycle: from PD directive to accepted implementation.

---

## The Project: TaskFlow

A CLI task management tool written in Python. The Wizard has already run, and
`docs/TEAM/` is fully set up.

**Owner/Dispatcher:** Alex
**Phase 1:** Core data model and storage
**Phase 2:** CLI commands (add, list, complete)
**Phase 3:** Filtering and search

---

## Session 1: Project Director — Initial Directive

**Alex starts a PD session:**

```
"Read docs/TEAM/PROJECT_DIRECTOR.md and follow the startup protocol.
This is the first session — the project is freshly initialized."
```

**PD reads all documents, then:**

1. Reviews PROJECT_STATUS.md — everything is NOT_STARTED
2. Writes a strategic log entry:

```markdown
### 2026-03-01 — DECISION

**Context:** Project initialized. Three phases planned. No blockers.
**Decision:** Start with Phase 1 (Core data model) as planned. Linear progression.
**Rationale:** Data model must exist before CLI can interact with it.
**Directive:** YES (DIRECTIVE_2026-03-01_start-phase1.md)
```

3. Creates the first directive:

**`DIRECTIVES/DIRECTIVE_2026-03-01_start-phase1.md`:**
```markdown
# Directive: Begin Phase 1 — Core Data Model

**Date:** 2026-03-01
**Priority:** HIGH
**Deadline:** none
**Status:** NEW

---

## Context
The project is starting from scratch. We need the foundational data model
before any user-facing features can be built.

## Request
Design and implement the core Task data model with persistent JSON storage.
Tasks should have: id, title, description, status (todo/done), created_at, completed_at.

## Expected Outcome
A working data model with CRUD operations and a test suite proving it works.
Storage should be file-based (JSON), not a database.

## Notes
Keep it simple. No categories, tags, or priorities in V1 — those can come later.
```

4. Updates PROJECT_STATUS.md §4:
```markdown
## 4. What's In Progress

Phase 1 (Core data model) — directive issued, awaiting DD task breakdown.
```

---

## Session 2: Development Director — Task Breakdown

**Alex starts a DD session:**

```
"Read docs/TEAM/DEVELOPMENT_DIRECTOR.md and follow the startup protocol.
PD just issued the first directive — check DIRECTIVES/ for it."
```

**DD reads all documents, then:**

1. Reads the directive — understands the scope
2. Updates directive status to PROCESSED
3. Creates TODO tasks:

**In `TODO.md`:**
```markdown
## Phase 1 — Core Data Model

**Goal:** Foundational Task data model with persistent JSON storage
**Priority:** HIGH
**Estimate:** 1 working session
**Depends on:** Phase 0 (Setup)

### 1.1. Task Model
- [ ] Create `src/models/task.py` with Task dataclass
- [ ] Fields: id (UUID), title (str), description (str), status (todo/done),
      created_at (datetime), completed_at (optional datetime)
- [ ] Validation: title cannot be empty, status must be "todo" or "done"

### 1.2. Storage Layer
- [ ] Create `src/storage/json_store.py` with JsonTaskStore class
- [ ] Methods: save(task), get(id), list_all(), update(task), delete(id)
- [ ] Storage file: `~/.taskflow/tasks.json`
- [ ] Use atomic writes (write to temp file, then rename)

### 1.3. Tests for Phase 1
- [ ] Unit tests for Task model (creation, validation, serialization)
- [ ] Unit tests for JsonTaskStore (CRUD operations)
- [ ] Test with empty store, single task, multiple tasks
- [ ] Test persistence (write, re-read, verify)

### 1.4. Deliverables
- [ ] `src/models/task.py`
- [ ] `src/storage/json_store.py`
- [ ] `tests/test_task.py`
- [ ] `tests/test_json_store.py`
- [ ] Report

### Acceptance Criteria for Phase 1
- Task model creates valid tasks with all required fields
- JsonTaskStore performs all CRUD operations correctly
- Data persists across store instances (write, close, re-open, read)
- All tests pass: `python -m pytest tests/ -v`
- No external dependencies (stdlib only)
```

4. Logs decision in DECISIONS.md:

```markdown
### 2026-03-01 — DECISION

**Context:** PD directive requests core data model with JSON storage.
**Decision:** Use dataclass for Task model, separate storage layer with atomic writes.
    Storage path: ~/.taskflow/tasks.json. UUID4 for task IDs.
**Rationale:** Dataclasses are lightweight and stdlib. Separate storage layer allows
    future backend changes. Atomic writes prevent data corruption.
```

5. Updates PROJECT_STATUS.md §2:
```markdown
| 1 | Core data model | IN_PROGRESS | Tasks created, ready for Team |
```

---

## Session 3: Development Team — Implementation

**Alex starts a Team session:**

```
"Read docs/TEAM/DEVELOPMENT_TEAM.md and follow the startup protocol.
Phase 1 tasks are ready in TODO.md. DD has approved the approach in DECISIONS.md.
Green light to start."
```

**Team reads TODO.md and DECISIONS.md, then implements:**

1. Creates `src/models/task.py` — Task dataclass with validation
2. Creates `src/storage/json_store.py` — JsonTaskStore with atomic writes
3. Creates `tests/test_task.py` — 8 tests for the model
4. Creates `tests/test_json_store.py` — 12 tests for storage
5. Runs tests: all 20 pass
6. Checks off all TODO items
7. Creates the report:

**`REPORTS/REPORT_2026-03-01_PHASE-1.md`:**
```markdown
# Report — Phase 1: Core Data Model

**Date:** 2026-03-01
**Status:** COMPLETED

---

## What Was Done
- Implemented Task dataclass in `src/models/task.py`
- Implemented JsonTaskStore in `src/storage/json_store.py` with atomic writes
- Full test coverage for both modules

## Created Files
| File | Purpose | Lines |
|------|---------|-------|
| `src/models/task.py` | Task dataclass with validation | 45 |
| `src/storage/json_store.py` | JSON file-based storage | 78 |
| `tests/test_task.py` | Task model tests | 62 |
| `tests/test_json_store.py` | Storage layer tests | 95 |

## Tests
- Total tests: 0 (existing) + 20 (new) = 20
- Status: ALL PASSING
- Command: `python -m pytest tests/ -v`

## Acceptance Criteria — Status
- [x] Task model creates valid tasks with all required fields
- [x] JsonTaskStore performs all CRUD operations correctly
- [x] Data persists across store instances
- [x] All tests pass
- [x] No external dependencies (stdlib only)

## Open Questions for Development Director
None.

## Suggestions for Next Phase
- The `list_all()` method currently loads all tasks into memory.
  For Phase 3 (filtering), consider adding query parameters to avoid loading
  everything when only a subset is needed.
```

---

## Session 4: Development Director — Review

**Alex starts a DD session:**

```
"Read docs/TEAM/DEVELOPMENT_DIRECTOR.md and follow the startup protocol.
Team submitted a report for Phase 1 — please review."
```

**DD reads the report, DECISIONS.md, and TODO.md, then:**

1. Verifies all acceptance criteria are checked
2. Notes the Team's suggestion about query parameters (good idea, will consider for Phase 3)
3. Logs the review:

```markdown
### 2026-03-01 — REVIEW

**Context:** Phase 1 report review. Team implemented Task model + JsonTaskStore.
**Decision:** ACCEPTED. All 5 acceptance criteria met. 20 tests passing.
    Good suggestion about query params for Phase 3 — will incorporate.
**Rationale:** Clean implementation, full test coverage, no issues found.
```

4. Updates PROJECT_STATUS.md §2:
```markdown
| 1 | Core data model | COMPLETED | Accepted 2026-03-01 |
```

---

## Session 5: Project Director — Status Update

**Alex starts a PD session:**

```
"Read docs/TEAM/PROJECT_DIRECTOR.md. Phase 1 was completed and accepted by DD.
Please update status and decide next steps."
```

**PD reads all documents, then:**

1. Updates PROJECT_STATUS.md §3:
```markdown
## 3. What's Completed

### Phase 1 — Core Data Model (2026-03-01)
- Task dataclass with UUID, validation
- JSON file storage with atomic writes
- 20 tests, all passing
```

2. Updates PROJECT_STATUS.md §4:
```markdown
## 4. What's In Progress

Phase 2 (CLI commands) — awaiting directive.
```

3. Writes strategic log entry:
```markdown
### 2026-03-01 — ASSESSMENT

**Context:** Phase 1 completed in a single session. Clean acceptance.
**Decision:** Proceed to Phase 2 as planned. No scope changes needed.
**Rationale:** Foundation is solid. Team's suggestion about query params is noted
    for Phase 3 consideration.
**Directive:** YES (DIRECTIVE_2026-03-01_start-phase2.md)
```

4. Updates the Phase 1 directive status:
```markdown
**Status:** COMPLETED
```

5. Issues directive for Phase 2...

**The cycle continues.**

---

## What Makes This Work

### 1. Clear Document Trail

After just one cycle, the project has:
- 1 directive (with status COMPLETED)
- 1 set of TODO tasks (all checked off)
- 1 implementation report
- 3 DECISIONS.md entries (1 DD decision, 1 DD review, setup guideline)
- 2 strategic log entries in PROJECT_STATUS.md

Any new session for any role can reconstruct the full history.

### 2. No Session Memory Required

If Session 3 had crashed halfway, a new Team session would:
- Read TODO.md (see unchecked items)
- Read DECISIONS.md (see technical guidelines)
- Know exactly what to do

### 3. Quality Gate

The Team doesn't decide when a phase is "done" — the DD does. The DD doesn't decide
what phase comes next — the PD does. Separation of concerns prevents shortcuts.

### 4. Honest Reporting

If the Team had reported PARTIAL (say, storage tests were failing), the DD would
issue NEEDS_FIXES, and the cycle would continue until all criteria are met.

---

## Example: Handling NEEDS_FIXES

What if the DD found issues? Here's how it plays out:

**DD Review verdict:**
```markdown
### 2026-03-01 — REVIEW

**Context:** Phase 1 report review.
**Decision:** NEEDS_FIXES.
    1. JsonTaskStore.delete() doesn't handle nonexistent IDs — should raise KeyError
    2. Task.completed_at is set on creation for "done" tasks — should only be set
       when transitioning from "todo" to "done"
**Rationale:** Both are correctness issues that affect Phase 2 CLI behavior.
```

**Alex starts a new Team session:**
```
"Read docs/TEAM/DEVELOPMENT_TEAM.md. DD reviewed your Phase 1 report — verdict
is NEEDS_FIXES. Check DECISIONS.md for the specific issues."
```

**Team fixes the issues, writes:**

**`REPORTS/REPORT_2026-03-01_PHASE-1_v2.md`:**
```markdown
# Report — Phase 1: Core Data Model (Revision)

**Date:** 2026-03-01
**Status:** COMPLETED

---

## What Was Done
- Fixed JsonTaskStore.delete() to raise KeyError for nonexistent IDs
- Fixed Task model: completed_at is now None on creation, set only via complete() method
- Added 3 new tests for the fixed behaviors

## Tests
- Total tests: 20 (existing) + 3 (new) = 23
- Status: ALL PASSING
...
```

**DD reviews v2 → ACCEPTED.** Cycle continues.

---

## Example: Multiple Phases in One Day

In practice, you can move fast. The ai-software-swarm project (which inspired this
framework) completed 7 phases in a single day:

```
09:00  PD: Initial directive for Phase 0
09:15  DD: Task breakdown for Phase 0
09:30  Team: Implements Phase 0
09:45  DD: Reviews → ACCEPTED
09:50  PD: Issues directive for Phase 1
10:00  DD: Task breakdown for Phase 1
10:30  Team: Implements Phase 1
11:00  DD: Reviews → ACCEPTED
...
17:00  Phase 6: ACCEPTED. V1 complete. 210 tests passing.
```

The framework doesn't slow you down — it keeps you organized while moving fast.

---

## Example: Documentation Optimization Session

After completing 3 phases, Alex notices sessions are getting slower — documents have
grown significantly.

**Alex starts a DO session:**

```
"Read docs/TEAM/DOC_OPTIMIZER.md. Phases 1-3 are all COMPLETED and ACCEPTED.
Please optimize documentation and archive completed phase content."
```

**DO reads all documents, then:**

1. Scans document sizes:
   - TODO.md: 180 lines (90 lines are completed Phase 1-3 tasks)
   - DECISIONS.md: 95 lines (40 lines are Phase 1-3 decisions/reviews)
   - DIRECTIVES/: 3 completed directive files
   - REPORTS/: 4 report files (including 1 revision)

2. Archives completed directives and reports to ARCHIVE/

3. Compresses completed TODO phases:
   - Before: 90 lines of checked-off Phase 1-3 tasks
   - After: 12-line summary per phase (36 lines total)

4. Extracts old DECISIONS.md entries to archive, leaves summary pointers

5. Logs everything in OPTIMIZATION_LOG.md:

```markdown
### 2026-03-05 — OPTIMIZATION

**Context:** Phases 1-3 completed. TODO.md had 90 lines of completed tasks.
**Action:** Compressed completed phases to summaries. Archived 3 directives, 4 reports.
**Impact:** TODO.md: 180 → 126 lines. DECISIONS.md: 95 → 67 lines. Archived: 7 files.
```

6. Reports to dispatcher:
   - "Archived 7 files. Reduced active document size by ~30%. Details in OPTIMIZATION_LOG.md."

---

## Example: Archive Knowledge Retrieval

During Phase 5, the Team needs to remember a technical decision from Phase 1.

**In the report:** "Open Questions: What was the rationale for using atomic writes
in the storage layer? This was decided in Phase 1 but the DECISIONS.md entry
was compressed."

**Alex starts a DO session:**

```
"Read docs/TEAM/DOC_OPTIMIZER.md. The Team needs the Phase 1 decision about
atomic writes in storage. Please search the archive."
```

**DO searches ARCHIVE_INDEX.md, finds the entry, writes:**

**`ARCHIVE/RETRIEVAL_RESPONSE.md`:**

```markdown
# Retrieval Response

**Requested by:** Development Team (via report)
**Query:** Rationale for atomic writes in storage layer
**Found in:** ARCHIVE/DECISIONS/DECISIONS_PHASE-1-3.md

**Result:**
> ### 2026-03-01 — DECISION
> **Context:** PD directive requests core data model with JSON storage.
> **Decision:** Use atomic writes (write to temp file, then rename).
> **Rationale:** Prevents data corruption if process crashes mid-write.
>     Atomic rename is guaranteed by POSIX on same filesystem.
```

**Alex tells the Team:** "DO found the answer — check ARCHIVE/RETRIEVAL_RESPONSE.md."
