# Izveštaj — Faza 2: Model Routing ("TinyDancer" princip)

**Datum**: 2026-02-25
**Status**: PASS

## Šta je urađeno

Centralizovan izbor modela: umesto da agenti biraju model direktno, sve ide kroz `select_tier()` router. Agenti koriste `resolve_llm_call()` utility metod koji automatski bira tier na osnovu task_type + risk_level.

## Kreirani fajlovi (2 nova)

| Fajl | Linija | Opis |
|------|--------|------|
| `config/models.py` | ~55 | ModelTier dataclass, MODEL_TIERS dict (tier1/tier2/tier3), get_tier(), env override |
| `core/model_router.py` | ~90 | RoutingDecision, select_tier(), routing_log, get/clear_routing_log() |

## Izmenjeni fajlovi (6)

| Fajl | Izmena |
|------|--------|
| `core/agent.py` | +import select_tier, +resolve_llm_call() metod (~12 linija) |
| `core/director.py` | +import select_tier, +tier_hints u analyze_task() (~10 linija) |
| `contexts/planning/agent.py` | llm_call → resolve_llm_call (1 linija) |
| `contexts/code_understanding/agent.py` | llm_call → resolve_llm_call (1 linija) |
| `contexts/feature_implementation/agent.py` | llm_call → resolve_llm_call (1 linija) |
| `config/__init__.py` | +re-export ModelTier, MODEL_TIERS, get_tier |
| `core/__init__.py` | +re-export select_tier, get_routing_log, clear_routing_log |

## Test fajl (1 novi)

| Fajl | Testova | Opis |
|------|---------|------|
| `tests/test_model_router.py` | 20 | Routing rules, metadata override, env override, routing log, agent integration |

## Routing pravila

| task_type | risk_level | Tier |
|-----------|------------|------|
| ANALYZE | LOW | tier1 (fast) |
| ANALYZE | MEDIUM/HIGH | tier2 (balanced) |
| PLAN | * | tier2 (balanced) |
| IMPLEMENT | HIGH | tier3 (deep) |
| IMPLEMENT | LOW/MEDIUM | tier2 (balanced) |
| REFACTOR | * | tier3 (deep) |
| TEST | * | tier2 (balanced) |
| DOC | * | tier1 (fast) |
| metadata override | * | explicit tier |

## Model Tier definicije

| Tier | Name | Model ID | Max Tokens | Timeout | Cost |
|------|------|----------|------------|---------|------|
| tier1 | fast | claude-haiku-4-5-20251001 | 4096 | 30s | low |
| tier2 | balanced | claude-sonnet-4-6 | 8192 | 90s | medium |
| tier3 | deep | claude-opus-4-6 | 16384 | 180s | high |

## Verifikacija

```
$ PYTHONPATH=. python -m pytest tests/ -v
64 passed in 1.44s

$ PYTHONPATH=. python -c "from core import select_tier; from config import ModelTier; print('OK')"
OK

$ git diff server/ remote/ swarm/ controller/
(prazan — ovi fajlovi NISU menjani)
```

## Ključne dizajn odluke

1. **Router kao pure function**: `select_tier()` prima SwarmTask, vraća ModelTier. Nema klasa, nema stanja osim loga.
2. **Agent.resolve_llm_call()**: Utility metod koji spaja router + llm_call. Agenti ne moraju da znaju za tiere.
3. **Metadata override**: `task.metadata["model_tier"]` eksplicitno bira tier — za debugging i specijalne slučajeve.
4. **Env override za model_id**: SWARM_MODEL_TIER1/2/3 menja model_id bez promene koda.
5. **Routing log**: Modul-level lista za audit, debugging, i analitiku.
6. **Backward compatible**: noop_llm_call i dalje radi — resolve_llm_call ga koristi uz tier timeout.
7. **ModelTier je frozen**: Immutable dataclass, sprečava slučajne mutacije.
