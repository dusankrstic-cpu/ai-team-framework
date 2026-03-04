# Claude Code integracija sa AI Software Swarm

Uputstvo za korišćenje swarm CLI-ja iz Claude Code sesija.

---

## 1. Pokretanje swarm-a iz Claude Code

Swarm CLI je Python modul koji se pokreće iz korena repozitorijuma:

```bash
# Aktiviraj virtualenv
source .venv/bin/activate

# Generiši plan za zadatak
PYTHONPATH=. python -m cli.main plan "Dodaj autentifikaciju u API"

# Izvrši puni flow (plan → analyze → implement)
PYTHONPATH=. python -m cli.main run "Implementiraj REST endpoint za korisnike"

# Analiziraj strukturu koda
PYTHONPATH=. python -m cli.main analyze /putanja/do/repoa

# Prikaži stanje sistema (konteksti, agenti, model tiere)
PYTHONPATH=. python -m cli.main status

# JSON output (za mašinsku obradu)
PYTHONPATH=. python -m cli.main --json plan "Opis zadatka"

# Dry-run (bez stvarnog LLM poziva — za testiranje)
PYTHONPATH=. python -m cli.main --dry-run run "Test zadatak"
```

### Environment varijable

| Varijabla | Opis |
|-----------|------|
| `SWARM_DRY_RUN=1` | Aktivira dry-run režim (noop LLM) bez `--dry-run` flaga |
| `SWARM_MODEL_TIER1` | Override model ID za tier1 (fast) |
| `SWARM_MODEL_TIER2` | Override model ID za tier2 (balanced) |
| `SWARM_MODEL_TIER3` | Override model ID za tier3 (deep) |

---

## 2. CLAUDE.md direktiva za projekat

Dodajte u CLAUDE.md ciljnog projekta da bi Claude Code koristio swarm za složene zadatke:

```markdown
## AI Software Swarm

Za složene zadatke koji zahtevaju planiranje, analizu i implementaciju,
koristi ai-software-swarm CLI:

```bash
# Aktiviraj swarm virtualenv
source /home/dusan/.openclaw/workspace/ai-software-swarm/.venv/bin/activate

# Generiši plan
PYTHONPATH=/home/dusan/.openclaw/workspace/ai-software-swarm \
  python -m cli.main plan "opis zadatka"

# Izvrši puni flow
PYTHONPATH=/home/dusan/.openclaw/workspace/ai-software-swarm \
  python -m cli.main run "opis zadatka"

# Analiziraj ovaj repo
PYTHONPATH=/home/dusan/.openclaw/workspace/ai-software-swarm \
  python -m cli.main analyze .
```

Koristi `--json` flag za strukturiran output koji možeš da parsiraš.
Za testiranje bez LLM poziva, dodaj `--dry-run`.
```

---

## 3. Primer prompt-a za Claude Code

Kada Dušan želi da koristi swarm kao orkestratora u Claude Code sesiji:

```
Ti si ai-software-swarm director za projekat X.

Tvoj posao:
1. Pokreni `python -m cli.main analyze <path>` da razumeš strukturu projekta.
2. Na osnovu analize, pokreni `python -m cli.main plan "opis zadatka"` za plan.
3. Pregledaj plan i pokreni `python -m cli.main run "opis zadatka"` za implementaciju.
4. Koristi --json flag kad trebaš da parsiraš output programski.

PYTHONPATH je: /home/dusan/.openclaw/workspace/ai-software-swarm
Virtualenv: /home/dusan/.openclaw/workspace/ai-software-swarm/.venv/bin/activate
```

---

## 4. Arhitektura integracije

```
Claude Code sesija
    │
    │  pokreće bash komandu
    ▼
cli/main.py (argparse)
    │
    │  instancira
    ▼
GlobalDirector + 3 BoundedContext-a
    │
    ├── PlanningContext (PlannerAgent, tier B)
    ├── CodeUnderstandingContext (CodeAnalyzerAgent, tier A)
    └── FeatureImplementationContext (ImplementerAgent, tier D)
    │
    │  task decomposition → routing → execution
    ▼
TaskResult (human-readable ili JSON)
```

CLI je tanak sloj — sva logika je u orkestracionom sloju (`core/director.py`).
