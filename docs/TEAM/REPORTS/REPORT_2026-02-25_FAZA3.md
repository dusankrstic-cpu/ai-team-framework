# Faza 3 — Governance i Trust Tiers

**Datum:** 2026-02-25
**Status:** PASS
**Testovi:** 91/91 (64 starih + 27 novih)

## Šta je implementirano

### Trust Tier sistem (A/B/C/D)

Bezbednosni sloj koji kontroliše koji agenti smeju da izvršavaju koje task tipove.

| Tier | Opis | Dozvoljeni task tipovi |
|------|------|----------------------|
| A | Read-only | ANALYZE, DOC |
| B | Draft | ANALYZE, DOC, PLAN, TEST |
| C | Apply | ANALYZE, DOC, IMPLEMENT, PLAN, TEST |
| D | Full | Svi (uključujući REFACTOR) |

| TaskType | Min tier |
|----------|----------|
| ANALYZE | A |
| DOC | A |
| PLAN | B |
| TEST | B |
| IMPLEMENT | C |
| REFACTOR | D |

### Enforcement — Defense in Depth

1. **BoundedContext.execute()** — autoritativni gate: `check_permission()` pre `handle_task()`
2. **GlobalDirector.execute_subtask()** — pre-check: `check_permission()` pre delegiranja na context

Oba nivoa loguju odluke — governance_log (modul-level) i Director decisions (instance-level).

### Dodeljeni trust tier-ovi

| Agent | Tier | Obrazloženje |
|-------|------|-------------|
| Agent (baza) | A (default) | Novi agenti počinju na najnižem tier-u |
| CodeAnalyzerAgent | A | ANALYZE je read-only |
| PlannerAgent | B | PLAN zahteva B |
| ImplementerAgent | D | Podržava REFACTOR koji zahteva D |

## Novi fajlovi

| Fajl | Opis |
|------|------|
| `config/governance.py` | TrustTier enum, MINIMUM_TIER, TRUST_TIERS, tier_allows(), get_minimum_tier() |
| `core/governance.py` | PermissionResult, GovernanceDecision, check_permission(), make_violation_result() |
| `tests/test_governance.py` | 27 unit testova za governance config i enforcement |
| `tests/test_governance_integration.py` | 12 integracionih testova sa custom agentima i Director pipeline |

## Izmenjeni fajlovi

| Fajl | Izmena |
|------|--------|
| `core/agent.py` | Default trust_tier: "B" → "A" |
| `core/context.py` | +check_permission() u execute() |
| `core/director.py` | +check_permission() u execute_subtask() |
| `contexts/planning/agent.py` | +trust_tier = "B" |
| `contexts/code_understanding/agent.py` | +trust_tier = "A" |
| `contexts/feature_implementation/agent.py` | +trust_tier = "D" |
| `config/__init__.py` | +export governance tipova |
| `core/__init__.py` | +export governance funkcija |
| `tests/test_core_context.py` | EchoAgent trust_tier="B", governance log cleanup fixture |

## Fajlovi koji NISU menjani

- `server/`, `remote/`, `swarm/`, `controller/` — verifikovano `git diff` (prazan)
- `core/task.py`, `config/models.py`, `core/model_router.py` — netaknuti
- `tests/test_model_router.py`, `tests/test_core_task.py`, `tests/test_core_agent.py` — netaknuti

## Napomena o circular import-u

`config/governance.py` koristi string ključeve u MINIMUM_TIER (umesto TaskType enum) da bi izbegao
circular import lanac: config.__init__ → config.governance → core.task → core.__init__ → core.context → core.governance → config.governance.
Kompatibilnost je garantovana jer je TaskType StrEnum — `TaskType.ANALYZE == "ANALYZE"` je True.

## Verifikacija

```
PYTHONPATH=. python -m pytest tests/ -v (91 passed)
from config import TrustTier, TRUST_TIERS → OK
from core import check_permission, PermissionResult → OK
git diff server/ remote/ swarm/ controller/ → prazan
```
