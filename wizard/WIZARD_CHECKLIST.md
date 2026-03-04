# Wizard Completeness Checklist

This document defines what the Wizard must generate and verify before finishing.
The Wizard uses this as a self-check before declaring initialization complete.

---

## Files to Generate

The Wizard generates all files inside `docs/TEAM/` in the user's project directory,
plus a launcher script.

### Role Definitions (3 files)

- [ ] `docs/TEAM/PROJECT_DIRECTOR.md` — Fully customized PD role definition
  - Project name, owner name filled in
  - Section 4 (About the Project) has real project details
  - All `[placeholder]` values replaced
  - No `<!-- WIZARD: -->` comments remain

- [ ] `docs/TEAM/DEVELOPMENT_DIRECTOR.md` — Fully customized DD role definition
  - Section 4 (Technical Standards) fully filled: test commands, conventions, dependencies, branch strategy
  - Review strictness calibrated to user preference
  - All `[placeholder]` values replaced
  - No `<!-- WIZARD: -->` comments remain

- [ ] `docs/TEAM/DEVELOPMENT_TEAM.md` — Fully customized Team role definition
  - Section 4 (Coding Conventions) is complete and specific
  - Section 5 (Testing Standards) has real test commands
  - Section 6 (Workflow Rules) has real policies
  - All `[placeholder]` values replaced
  - No `<!-- WIZARD: -->` comments remain

### State Files (4 files)

- [ ] `docs/TEAM/PROJECT_STATUS.md` — Initialized project status
  - Section 1 has real project info
  - Section 2 has initial phase table (pre-populated)
  - Section 7 has real team info with owner name
  - Remaining sections are properly empty/initialized

- [ ] `docs/TEAM/DECISIONS.md` — Initialized decisions log
  - Project name in header
  - Optionally seeded with initial GUIDELINE entry for coding conventions

- [ ] `docs/TEAM/TODO.md` — Initialized task backlog
  - Phase 0 (Setup) properly customized for tech stack
  - Additional phases from user input included with standard structure
  - Dependency graph populated

- [ ] `docs/TEAM/ARCHITECTURE_VISION.md` — Initialized architecture vision
  - All sections filled based on user's project description
  - Tech stack table complete
  - Module structure reflects actual project layout
  - Principles derived from user's preferences

### Format References (2 files)

- [ ] `docs/TEAM/DIRECTIVE_TEMPLATE.md` — Copied as-is from framework templates
- [ ] `docs/TEAM/REPORT_TEMPLATE.md` — Copied as-is from framework templates

### Directories (2 directories)

- [ ] `docs/TEAM/DIRECTIVES/` — Created (empty, ready for PD)
- [ ] `docs/TEAM/REPORTS/` — Created (empty, ready for Team)

### Launcher Script (1 file)

- [ ] `start_role.sh` — Parameterized script in project root
  - Accepts role argument (pd / dd / team)
  - Loads correct role file into Claude Code session
  - Executable (`chmod +x`) instruction present

---

## Quality Checks

Before finishing, verify:

- [ ] **No placeholders remain** — Search all generated files for `[` brackets that look like unfilled placeholders
- [ ] **No WIZARD comments** — Search for `<!-- WIZARD` in generated files
- [ ] **Cross-references are consistent** — File paths mentioned in role definitions match actual generated file paths
- [ ] **Section numbers match** — References to "section 2", "section 8", etc. match actual numbering
- [ ] **Owner name is consistent** — Same name used everywhere
- [ ] **Project name is consistent** — Same name used everywhere
- [ ] **Test command is consistent** — Same command in DD and Team role files
- [ ] **Coding conventions match** — DD's Section 4 and Team's Section 4 agree on all conventions
- [ ] **Communication language applied consistently** — All generated content uses the user's chosen language

---

## Information Gathered

The Wizard must have answers to all of these before generating:

### Phase 1 — Project Basics
- [ ] Communication language
- [ ] Project name
- [ ] Project description (1-2 paragraphs)
- [ ] Tech stack (languages, frameworks, key dependencies)
- [ ] Repository URL (optional)
- [ ] Owner/dispatcher name

### Phase 2 — Team Preferences
- [ ] Number of initial phases (and their names/descriptions)
- [ ] Autonomy level: strict / moderate / high
- [ ] Review strictness: strict / moderate / lenient
- [ ] Dispatcher control level: full control / PD + DD / PD only

### Phase 3 — Technical Context
- [ ] Test command(s)
- [ ] Dependency policy (stdlib-only / conservative / liberal)
- [ ] Key architectural concepts
- [ ] Module/component structure

### Phase 4 — Coding Conventions
- [ ] Naming conventions (files, classes, functions, variables, constants)
- [ ] Branch strategy and commit conventions
- [ ] Any special rules or constraints
