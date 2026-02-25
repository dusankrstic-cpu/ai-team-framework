# Directive: [Title]

<!-- WIZARD: This is a format reference. The Wizard does NOT customize this file —
     it ships as-is into the user's project. It defines the standard format that
     the Project Director uses when issuing directives. -->

**Date:** YYYY-MM-DD
**Priority:** HIGH / MEDIUM / LOW
**Deadline:** YYYY-MM-DD or "none"
**Status:** NEW / PROCESSED / COMPLETED

---

## Context

Why this directive exists. What strategic situation triggered it. Reference relevant
milestones, risks, or previous decisions.

## Request

What exactly the Development Director should achieve — stated as a goal, not as
implementation detail. The DD decides *how*; the PD decides *what* and *why*.

## Expected Outcome

What the world looks like when this is done. Observable results, not process steps.

## Notes

Additional context, constraints, references to other documents. Optional section —
omit if empty.

---

## Status Lifecycle

| Status | Meaning |
|--------|---------|
| **NEW** | Just issued. DD has not yet read it. |
| **PROCESSED** | DD has read it and created TODO items. |
| **COMPLETED** | All related tasks are done and reviewed. |

The Project Director sets the initial status to NEW.
The Development Director updates to PROCESSED after reading and creating tasks.
The Project Director updates to COMPLETED after confirming all work is done.

## Naming Convention

```
DIRECTIVE_YYYY-MM-DD_topic-slug.md
```

Examples:
- `DIRECTIVE_2026-03-01_authentication-system.md`
- `DIRECTIVE_2026-03-05_priority-reorder-phase3.md`
- `DIRECTIVE_2026-03-10_scope-reduction-v2.md`
