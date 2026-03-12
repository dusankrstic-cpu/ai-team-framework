# Project Status

<!-- WIZARD: Customize this file for the user's project.
     - Section 1: Project name, description, tech stack
     - Section 2: Pre-populate phase table from user's initial phases
     - Section 7: Project owner name
     - Section 9: Update file paths if needed
     - All other sections start mostly empty (filled during project execution)
     Remove all WIZARD comments in the generated version. -->

---

## Section Ownership

| Section | Written By | Notes |
|---------|-----------|-------|
| 1. About the Project | PD | Rarely changes |
| 2. Phases (table + graph) | **DD** | Updated after each review |
| 3. What's Completed | PD | Based on DD's reports |
| 4. What's In Progress | PD | Based on DD's reports |
| 5. Risks | PD | Strategic risks |
| 6. Milestones | PD | Strategic decisions |
| 7. Team | PD | Rarely changes |
| 8. Strategic Log | **PD only** | PD's permanent memory |
| 9. Key Documents | PD | Rarely changes |

**Critical rule:** DD NEVER writes in sections 3-9. PD NEVER writes in section 2.
This prevents conflicts.

---

## 1. About the Project

<!-- WIZARD: Fill from project basics -->

**Name:** [Project Name]
**Description:** [One-paragraph description]
**Tech Stack:** [Languages, frameworks, key dependencies]
**Repository:** [Repo URL if provided]

---

## 2. Phases

<!-- WIZARD: Pre-populate from user's initial phase list.
     Example format below. -->

| # | Phase | Status | Notes |
|---|-------|--------|-------|
| 0 | Setup and framework | NOT_STARTED | |
| 1 | [Phase 1 name] | NOT_STARTED | |
| 2 | [Phase 2 name] | NOT_STARTED | |

**Status values:** NOT_STARTED / IN_PROGRESS / COMPLETED / BLOCKED

### Dependency Graph

<!-- WIZARD: Generate based on user's phase dependencies, or leave a simple
     linear chain if no specific dependencies were given. -->

```
Phase 0 ──► Phase 1 ──► Phase 2 ──► ...
```

---

## 3. What's Completed

*Nothing yet — project is starting.*

---

## 4. What's In Progress

*Nothing yet — project is starting.*

---

## 5. Risks

*No risks identified yet.*

---

## 6. Milestones

<!-- WIZARD: Pre-populate if user provided milestones, otherwise leave empty -->

| Milestone | Target | Status |
|-----------|--------|--------|
| [Milestone 1] | [Date or "TBD"] | PENDING |

---

## 7. Team

| Role | Description |
|------|-------------|
| **[Owner Name]** | Project owner, dispatcher between AI roles |
| **Project Director** | Strategic authority — vision, priorities, scope |
| **Development Director** | Technical authority — architecture, reviews, task management |
| **Development Team** | Implementation — code, tests, reports |
| **Documentation Optimizer** | Knowledge curator — documentation cleanup, archival, retrieval |

---

## 8. Strategic Log

*The Project Director logs strategic decisions here. Format:*

```markdown
### YYYY-MM-DD — [Type: DECISION / ASSESSMENT / CORRECTION]

**Context:** [Situation]
**Decision:** [What was decided]
**Rationale:** [Why]
**Directive:** [YES (link) / NO]
```

---

## 9. Key Documents

| Document | Purpose |
|----------|---------|
| `PROJECT_DIRECTOR.md` | PD role definition |
| `DEVELOPMENT_DIRECTOR.md` | DD role definition |
| `DEVELOPMENT_TEAM.md` | Team role definition |
| `TODO.md` | Task backlog (DD manages) |
| `DECISIONS.md` | Technical decisions (DD writes) |
| `ARCHITECTURE_VISION.md` | Technical vision |
| `DIRECTIVES/` | PD's strategic directives |
| `REPORTS/` | Team's implementation reports |
| `DOC_OPTIMIZER.md` | DO role definition |
| `OPTIMIZATION_LOG.md` | Optimization log (DO writes) |
| `ARCHIVE_INDEX.md` | Archive index (DO writes) |
| `ARCHIVE/` | Archived documents (DO manages) |
