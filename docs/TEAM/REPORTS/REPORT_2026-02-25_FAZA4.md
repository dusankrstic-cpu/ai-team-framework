# Izveštaj — Faza 4: ReasoningBank i Dream Cycles

**Datum:** 2026-02-25
**Status:** ZAVRŠENO

---

## Šta je urađeno

Implementiran sistem pamćenja swarma: ReasoningBank za čuvanje iskustava u JSONL formatu, dream cycle mehanizam za generisanje lekcija, i integracija sa GlobalDirector-om (log_entry nakon svakog taska, search/enrich pre planiranja) i CLI-jem (swarm history → pravi ReasoningBank umesto stuba).

## Kreirani fajlovi

| Fajl | Svrha | Linije |
|------|-------|--------|
| `reasoning/bank/__init__.py` | ReasoningBank, BankEntry, log_entry/search/recent/count | ~155 |
| `reasoning/dream_cycle.py` | Dream cycle: čita zapise, LLM generiše lekcije, upisuje u lessons/ | ~130 |
| `tests/test_reasoning_bank.py` | 24 unit testa za BankEntry, log_entry, search, recent, count | ~200 |
| `tests/test_dream_cycle.py` | 9 testova za dream cycle i load_lessons | ~100 |
| `tests/test_reasoning_integration.py` | 9 integration testova: Director+Bank+CLI | ~105 |

## Izmenjeni fajlovi

| Fajl | Izmena |
|------|--------|
| `core/director.py` | +reasoning_bank field, +_enrich_with_lessons(), +_log_to_bank(), handle() koristi oba |
| `cli/main.py` | +ReasoningBank import, _build_director() koristi bank, cmd_history() pravi implementacija |
| `reasoning/__init__.py` | +re-export ReasoningBank, BankEntry, run_dream_cycle, load_lessons |
| `tests/test_cli.py` | History testovi ažurirani za novu implementaciju (ne stub) |
| `docs/TEAM/TODO.md` | Čekirani svi Faza 4 checkbox-ovi |

## Fajlovi koji NISU menjani

- `server/`, `remote/`, `swarm/`, `controller/` — verifikovano `git diff` (prazan)
- `core/task.py`, `core/agent.py`, `core/context.py` — netaknuti
- `config/models.py`, `config/governance.py`, `core/model_router.py`, `core/governance.py` — netaknuti
- `contexts/` — svi agenti i context factory-ji netaknuti

## Arhitekturne odluke

### 1. Kod u reasoning/bank/__init__.py (ne reasoning/bank.py)

`reasoning/bank/` direktorijum je kreiran u Fazi 0 sa `__init__.py`. Python preferira paket nad modulom istog imena. Stoga je ReasoningBank kod stavljen u `reasoning/bank/__init__.py` a `entries.jsonl` živi u istom direktorijumu.

### 2. Circular import: core → reasoning

`core/director.py` importuje iz `reasoning.bank`, ali `reasoning.bank` importuje iz `core.task`. Ovo stvara circular import lanac: `reasoning.bank → core.task → core.__init__ → core.director → reasoning.bank`.

**Rešenje:** Lazy import u `core/director.py` — `from reasoning.dream_cycle import load_lessons` se importuje unutar `_enrich_with_lessons()` metode, ne na module level. `reasoning_bank` field koristi `Any` tip umesto `ReasoningBank` da izbegne import na vrhu.

### 3. Director integracija

- **`_enrich_with_lessons(task)`**: Pre planiranja — učitava lekcije iz dream cycle fajlova + nedavne zapise iz bank-a, dodaje u `task.metadata["reasoning_lessons"]`.
- **`_log_to_bank(task, result)`**: Nakon izvršenja — upisuje task_type, description, decisions (poslednjih 5) i suggestions (prvih 3) kao lekcije.
- Oba su opcionalna (noop ako `reasoning_bank is None`) — backward compatible.

### 4. CLI history: stub → prava implementacija

`cmd_history()` sada koristi pravi `ReasoningBank.search()` / `ReasoningBank.recent()`. Human-readable format prikazuje timestamp, task_id, tip, ishod, projekat, opis i lekcije. JSON format vraća `{"count": N, "entries": [...]}`.

## Testovi

- Ukupno testova: **176** (134 starih + 42 novih)
- Status: **SVI PROLAZE**
- Komanda: `PYTHONPATH=. .venv/bin/python -m pytest tests/ -v`

### Novi test fajlovi (3 fajla, 42 testova)

| Fajl | Testova | Opis |
|------|---------|------|
| `tests/test_reasoning_bank.py` | 24 | BankEntry (3), log_entry (7), search (9), recent (3), count (2) |
| `tests/test_dream_cycle.py` | 9 | run_dream_cycle (6), load_lessons (3) |
| `tests/test_reasoning_integration.py` | 9 | Director+Bank (7), CLI history (2) |

## Kriterijum prihvatanja — status

- [x] Nakon izvršenog taska, zapis postoji u `entries.jsonl` — **verifikovano: Director.handle() → _log_to_bank() → entries.jsonl**
- [x] `search()` vraća relevantne rezultate po projektu i domenu — **9 search testova pokrivaju sve filtere**
- [x] Dream cycle skripta generiše čitljive lekcije — **6 testova, uključujući header format i project filter**
- [x] Svi testovi prolaze — **176/176**

## Otvorena pitanja za direktora razvoja

Nema.

## Predlozi za sledeću fazu

- Faza 6 (Hardening) je jedina preostala faza. Svi preduveti su ispunjeni (Faze 0-5 prihvaćene).
- ReasoningBank `entries.jsonl` će rasti sa upotrebom — u Fazi 6 bi trebalo razmotriti rotaciju ili kompresiju starijih zapisa (slično `rotate_logs.py` iz Savka projekta).
- Dream cycle bi mogao da se integriše kao cron job u Fazi 6 (npr. jednom dnevno ili nedeljno).
