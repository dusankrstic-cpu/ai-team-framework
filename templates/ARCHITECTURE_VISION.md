# Architecture Vision

<!-- WIZARD: Customize this file for the user's project.
     - Section 1: Project name, high-level architecture description
     - Section 2: Key architectural concepts from user input
     - Section 3: Tech stack details
     - Section 4: Module/component structure based on user's description
     - Section 5: Principles based on user's stated preferences
     This file is read-only for the Team, read-only for PD,
     and the DD can propose changes via VISION_CHANGE_PROPOSAL in DECISIONS.md.
     Remove all WIZARD comments in the generated version. -->

**Owner:** Shared (PD + DD approve changes)
**Purpose:** The technical north star. All implementation decisions should align with
this document. Changes require a VISION_CHANGE_PROPOSAL in DECISIONS.md, approved by
both PD and DD.

---

## 1. Overview

**[Project Name]** — [one-paragraph architectural summary describing what the system
does and how it's structured at the highest level].

---

## 2. Key Concepts

<!-- WIZARD: Fill in based on user's description of their project's
     core architectural concepts. Examples:
     - "Bounded contexts with domain-driven design"
     - "Microservices communicating via message queue"
     - "Monolithic MVC with clear layer separation"
     - "CLI tool with plugin architecture"
     Each concept gets a brief description of what it means in this project. -->

### 2.1. [Concept 1]

[Description of this concept and why it matters]

### 2.2. [Concept 2]

[Description]

---

## 3. Tech Stack

<!-- WIZARD: Detailed tech stack from user input -->

| Layer | Technology | Notes |
|-------|-----------|-------|
| Language | [e.g., Python 3.10+] | [constraints] |
| Framework | [e.g., FastAPI, Express, none] | |
| Database | [e.g., PostgreSQL, SQLite, none] | |
| Testing | [e.g., pytest, jest] | |
| Other | [e.g., Docker, Redis] | |

---

## 4. Module Structure

<!-- WIZARD: Project-specific module/component layout.
     Draw from user's description of what the project does. -->

```
[project-root]/
├── [source-dir]/
│   ├── [module-1]/        # [purpose]
│   ├── [module-2]/        # [purpose]
│   └── [module-3]/        # [purpose]
├── [test-dir]/
│   └── ...
└── docs/
    └── TEAM/              # AI team management files
```

---

## 5. Principles

<!-- WIZARD: Derive from user's stated preferences and conventions.
     Examples of principles:
     - "Simplicity over abstraction — no premature generalization"
     - "Test-driven — tests before implementation"
     - "Iterative — start small, prove it works, then extend"
     - "No external dependencies — stdlib only"
     - "Defense in depth — validate at every layer" -->

1. **[Principle 1]** — [explanation]
2. **[Principle 2]** — [explanation]
3. **[Principle 3]** — [explanation]

---

## 6. Constraints

<!-- WIZARD: Any hard constraints the user mentioned -->

- [e.g., "Must run on Python 3.10+ without virtual environment"]
- [e.g., "No cloud dependencies — must work fully offline"]
- [e.g., "Response time < 100ms for all API endpoints"]

---

## 7. Future Considerations

*Architectural ideas that are explicitly out of scope for now but may be relevant
later. Listed here so they inform current design without driving it.*

- [e.g., "V2 may add a web UI — keep backend API-friendly"]
- [e.g., "Clustering support deferred — but don't use in-process singletons"]

---

## Change Process

This document is the architectural contract. To change it:

1. DD writes a **VISION_CHANGE_PROPOSAL** in DECISIONS.md
2. PD reviews the strategic impact
3. If both approve, DD updates this file
4. DD issues a GUIDELINE in DECISIONS.md noting the change

No one modifies this file unilaterally.
