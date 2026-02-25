# Development Backlog

<!-- WIZARD: Customize this file for the user's project.
     - Add phases from user's initial phase list
     - Each phase gets the standard structure (Goal, Priority, Estimate, Depends on,
       task groups, tests section, deliverables section, acceptance criteria)
     - If the user provided specific tasks, include them
     - If not, create reasonable skeleton tasks based on the phase descriptions
     Remove all WIZARD comments in the generated version. -->

**Owner:** Development Director
**Purpose:** The authoritative task backlog. The Development Team reads this as their
work orders. Only the DD modifies task text; the Team only checks boxes.

---

## How to Use This File

### For the Development Director
- Create phase entries with the standard structure (see below)
- Break directives into concrete, testable tasks
- Set priorities and dependencies
- Update after reviews (add tasks, adjust scope)

### For the Development Team
- Read assigned phase tasks before starting work
- Check boxes (`- [ ]` → `- [x]`) as you complete tasks
- Do NOT modify task text, reorder, add, or delete tasks
- Flag issues in your report, not by editing this file

---

## Phase Structure Template

```markdown
## Phase N — [Name]

**Goal:** [Strategic goal]
**Priority:** HIGHEST / HIGH / MEDIUM / LOW
**Estimate:** X-Y working sessions
**Depends on:** [Previous phases or "None"]

### N.1. [Component Group]
- [ ] Task description
- [ ] Task with implementation details

### N.2. [Another Component Group]
- [ ] Task description

### N.X. Tests for Phase N
- [ ] Unit tests for [component]
- [ ] Integration tests for [interaction]

### N.Y. Deliverables
- [ ] [Expected output 1]
- [ ] [Expected output 2]
- [ ] Tests
- [ ] Report

### Acceptance Criteria for Phase N
[Explicit, testable criteria that the DD will verify during review]
```

---

## Dependency Graph

<!-- WIZARD: Generate based on user's phase dependencies -->

```
Phase 0 ──► Phase 1 ──► Phase 2 ──► ...
```

---

## Phase 0 — Setup and Framework

**Goal:** Establish project structure, verify tooling, confirm conventions.
**Priority:** HIGHEST
**Estimate:** 1 working session
**Depends on:** None

<!-- WIZARD: Customize Phase 0 tasks based on tech stack.
     Examples for Python: create dirs, setup pytest, verify imports
     Examples for Node: create dirs, setup jest, verify builds
     Examples for Go: create dirs, setup go test, verify compilation -->

### 0.1. Project Structure
- [ ] Create source directories
- [ ] Create test directories
- [ ] Verify tooling works (test runner, linter if configured)

### 0.2. Deliverables
- [ ] Working project skeleton
- [ ] Test runner configured and passing (even with zero tests)
- [ ] Report

### Acceptance Criteria for Phase 0
- Project structure matches ARCHITECTURE_VISION.md
- Test command runs successfully
- All team members can read their role files and understand the structure

---

<!-- WIZARD: Add remaining phases here based on user input.
     Each phase follows the same structure as above. -->
