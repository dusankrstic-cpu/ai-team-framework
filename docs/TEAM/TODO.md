# TODO.md — ai-software-swarm Development Tasks

Ovaj fajl je operacionalizacija vizije iz `DEVELOPMENT_DIRECTOR.md`. Organizovan je po fazama sa jasnim deliverable-ima i kriterijumima prihvatanja. Tim radi fazu po fazu — **ne preskačite faze**.

**Izveštaje pišite u `docs/TEAM/REPORTS/REPORT_<datum>_<faza>.md`.**

---

## Graf zavisnosti faza

```
Faza 0  ──►  Faza 1  ──►  Faza 2  ──►  Faza 5 (CLI)
                │              │
                │              ▼
                │          Faza 4 (ReasoningBank)
                │              │
                ▼              ▼
             Faza 3 (Governance) ──►  Faza 6 (Hardening)
```

- Faza 0 je preduslov za sve.
- Faza 1 je preduslov za Fazu 2, 3 i 4.
- Faza 2 (routing) i Faza 4 (ReasoningBank) mogu da se rade **paralelno** nakon Faze 1.
- Faza 3 (governance) zavisi od Faze 1 ali može da počne paralelno sa Fazom 2.
- Faza 5 (CLI) zavisi od Faze 1 i 2.
- Faza 6 je finalna integracija.

---

## Faza 0 — Priprema i okvir

**Cilj:** Razumeti šta imamo i pripremiti teren za nove module.
**Prioritet:** NAJVIŠI — ovo je preduslov za sve ostalo.
**Procena:** 1-2 radna dana.

### 0.1. Pregled postojećeg stanja

- [ ] Mapirati postojeće module i njihove odgovornosti:
  - [ ] `server/main_ws.py` — šta tačno radi, koji su javni interfejsi.
  - [ ] `remote/worker_ws.py` — koji executori postoje, kako se dispatch radi.
  - [ ] `swarm/protocol.py` — koje poruke i dataclass-ovi postoje.
  - [ ] `controller/dispatcher_ws.py` — programski interfejs.
  - [ ] `scripts/swarm_controller.py` — CLI interfejs.
- [ ] Identifikovati gde se trenutno radi orkestracija (odgovor: nigde eksplicitno — to je ceo smisao novog dizajna).
- [ ] Popisati gde se koji modeli koriste (odgovor: `llm.call` executor poziva Claude CLI).
- [ ] Dokumentovati konekciju između postojećeg MVP-a i novog Director sloja — napisati kratak `docs/TEAM/BRIDGE.md` koji opisuje kako će novi `core/` koristiti postojeći `server/` i `remote/`.

### 0.2. Kreiranje direktorijumske strukture

- [ ] Kreirati nove direktorijume sa `__init__.py` i kratkim `README.md`:
  - [ ] `core/` — zajedničke apstrakcije (Task, Agent, Context, ModelRouter, Governance).
  - [ ] `contexts/` — bounded contexts (za sada samo 3: planning, code-understanding, feature-implementation).
  - [ ] `contexts/planning/` — planning-orchestrator context.
  - [ ] `contexts/code_understanding/` — code-understanding context.
  - [ ] `contexts/feature_implementation/` — feature-implementation context.
  - [ ] `reasoning/` — ReasoningBank, dream cycles (prazan za sada, priprema za Fazu 4).
  - [ ] `cli/` — komandna linija (prazan za sada, priprema za Fazu 5).
  - [ ] `config/` — konfiguracioni fajlovi (models, governance).
- [ ] Ne menjati postojeće `server/`, `remote/`, `swarm/`, `controller/` module — oni ostaju kao infrastrukturni sloj.

### 0.3. Deliverables

- [ ] `docs/TEAM/BRIDGE.md` — dokument o vezi starog i novog.
- [ ] Svi novi direktorijumi kreirani sa `__init__.py` i `README.md`.
- [ ] Izveštaj u `docs/TEAM/REPORTS/REPORT_<datum>_FAZA0.md`.

### Kriterijum prihvatanja Faze 0

Faza 0 je gotova kada:
- Svi direktorijumi postoje sa `__init__.py` i `README.md`.
- `BRIDGE.md` jasno opisuje kako novi sloj poziva stari.
- Postojeći testovi i dalje prolaze (`python -m pytest tests/ -v`).

---

## Faza 1 — Bounded Contexts i Director sloj

**Cilj:** Uspostaviti core apstrakcije i minimalni GlobalDirector koji radi task decomposition na 3 konteksta.
**Prioritet:** KRITIČNO — ovo je srce sistema, bez njega ostale faze nemaju smisla.
**Procena:** 3-5 radnih dana.
**Zavisi od:** Faza 0.

### 1.1. Core apstrakcije (`core/`)

- [x] `core/task.py` — Definisati osnovni model zadatka:
  - [x] `SwarmTask` dataclass sa: id, description, project_context (repo, branch), priority (low/medium/high/critical), risk_level (low/medium/high), task_type (enum: `PLAN`, `IMPLEMENT`, `REFACTOR`, `TEST`, `DOC`, `ANALYZE`), expected_output, parent_task_id (za subtask hijerarhiju), metadata dict.
  - [x] `TaskResult` dataclass sa: task_id, status (completed/failed/partial), output, log, suggestions (lista narednih koraka), duration_ms.

- [x] `core/agent.py` — Definisati interfejs za agenta:
  - [x] Bazna klasa `Agent` sa: agent_id, name, description, supported_task_types, trust_tier.
  - [x] Metoda `handle_task(task: SwarmTask) -> TaskResult`.
  - [x] Metoda `can_handle(task: SwarmTask) -> bool` — da li agent podržava ovaj tip.

- [x] `core/context.py` — Definisati interfejs za bounded context:
  - [x] `BoundedContext` klasa sa: name, description, task_types (lista podržanih tipova), agents (lista registrovanih agenata), policy (dict sa pravilima).
  - [x] Metoda `route_task(task: SwarmTask) -> Agent` — bira agenta za task.
  - [x] Metoda `execute(task: SwarmTask) -> TaskResult` — orkestrira izvršenje unutar konteksta.

### 1.2. GlobalDirector (`core/director.py`)

- [x] Implementirati `GlobalDirector` koji:
  - [x] Prima high‑level `SwarmTask` (iz CLI-ja ili programski).
  - [x] Radi **task analysis**: čita opis, identifikuje projekat, procenjuje rizik.
  - [x] Radi **decomposition**: deli na subtasks i mapira ih na registrovane BoundedContext-e.
  - [x] Orkestrira izvršenje: sekvencijalno u V1, paralelno u V2 kad bude potrebe.
  - [x] Agregira `TaskResult`-e od svih subtaskova i generiše finalni konsolidovani rezultat.
  - [x] Loguje sve odluke (koji context, zašto, koliko subtaskova).

- [x] Integracija sa postojećim swarm-om:
  - [x] `GlobalDirector` može da koristi `controller/dispatcher_ws.py` za slanje taskova na remote workere.
  - [x] Lokalni agenti (code-understanding, planning) rade direktno bez WS-a.
  - [x] Remote agenti (feature-implementation koji treba da pokrene shell/python) idu kroz WS.

### 1.3. Prva trojka bounded contexts

**VAŽNO:** U V1 svaki context ima **jednog agenta**. Domain Directors se ne prave dok se ne pokaže potreba.

- [x] `contexts/planning/` — PlanningContext:
  - [x] Agent: `PlannerAgent` — prima task, koristi LLM da generiše plan sa subtaskovima.
  - [x] Input: high-level opis zadatka + project context.
  - [x] Output: lista `SwarmTask` subtaskova sa tipom, prioritetom i redosledom.

- [x] `contexts/code_understanding/` — CodeUnderstandingContext:
  - [x] Agent: `CodeAnalyzerAgent` — analizira strukturu koda/repoa.
  - [x] Input: putanja do repo-a/modula + pitanje/zadatak.
  - [x] Output: analiza (struktura, entrypointi, dependencies, sažetak).

- [x] `contexts/feature_implementation/` — FeatureImplementationContext:
  - [x] Agent: `ImplementerAgent` — generiše konkretne promene koda.
  - [x] Input: specifikacija (iz plana) + code analysis (iz code-understanding).
  - [x] Output: predlog promena (fajlovi, diference, patch).

### 1.4. Testovi za Fazu 1

- [x] Unit testovi za `SwarmTask` i `TaskResult` (kreiranje, serijalizacija).
- [x] Unit testovi za `Agent.can_handle()` i `BoundedContext.route_task()`.
- [x] Integration test: `GlobalDirector` prima task → decomposition → context routing → rezultat.
- [x] Smoke test: ceo flow sa jednim prostim zadatkom (npr. "analiziraj strukturu ovog repoa").

### 1.5. Deliverables

- [x] `core/task.py`, `core/agent.py`, `core/context.py`, `core/director.py` — implementirani i testirani.
- [x] 3 bounded context-a sa po jednim agentom.
- [x] Testovi koji prolaze.
- [x] Izveštaj u `docs/TEAM/REPORTS/REPORT_<datum>_FAZA1.md`.

### Kriterijum prihvatanja Faze 1

Faza 1 je gotova kada:
- `GlobalDirector` može da primi tekstualni zadatak i vrati strukturiran rezultat.
- Bar jedan end-to-end flow radi: task → planning → code-understanding → rezultat.
- Svi testovi prolaze (stari + novi).
- Kod je čist, nema duplikacije sa postojećim modulima.

---

## Faza 2 — Model Routing ("TinyDancer" princip)

**Cilj:** Centralizovati izbor modela tako da Director-i i agenti ne biraju model direktno.
**Prioritet:** VISOK.
**Procena:** 2-3 radna dana.
**Zavisi od:** Faza 1.

### 2.1. Model tier definicije

- [x] `config/models.py` (ili `config/models.json`) — konfiguracioni fajl:
  - [x] Definisati `tier1` (fast/cheap): model ID, max tokens, timeout, cost hint.
  - [x] Definisati `tier2` (balanced): model ID, max tokens, timeout, cost hint.
  - [x] Definisati `tier3` (deep/expensive): model ID, max tokens, timeout, cost hint.
  - [x] Podržati override po okruženju (dev vs prod).

### 2.2. Model router modul

- [x] `core/model_router.py`:
  - [x] `select_tier(task: SwarmTask, context: str, risk: str) -> ModelTier` — glavna routing funkcija.
  - [x] Routing logika:
    - [x] `ANALYZE` + low risk → tier 1.
    - [x] `PLAN`, `IMPLEMENT`, `TEST` + medium risk → tier 2.
    - [x] `IMPLEMENT` + high risk, `REFACTOR` + large scope, consensus → tier 3.
  - [x] Override mehanizam: task metadata može eksplicitno da zatraži tier.

- [x] Integrisati router u:
  - [x] `GlobalDirector` — za task analysis i decomposition.
  - [x] Agente u bounded contexts — za LLM pozive unutar agenata.

- [x] Logging: svaki izbor modela se loguje (task_id → tier → razlog → timestamp).

### 2.3. Deliverables

- [x] `config/models.py`, `core/model_router.py` — implementirani i testirani.
- [x] Unit testovi za routing logiku (5+ scenarija).
- [x] `GlobalDirector` i agenti koriste router umesto hardkodiranog modela.
- [x] Izveštaj u `docs/TEAM/REPORTS/REPORT_<datum>_FAZA2.md`.

### Kriterijum prihvatanja Faze 2

- Router ispravno bira tier za svaki tip zadatka.
- Nijedan agent ne poziva model direktno — sve ide kroz router.
- Log fajl beleži svaku routing odluku.
- Svi testovi prolaze.

---

## Faza 3 — Governance i Trust Tiers

**Cilj:** Zaštititi sistem od neželjenih akcija — definisati ko šta sme.
**Prioritet:** VISOK (bezbednosno kritično).
**Procena:** 3-5 radnih dana.
**Zavisi od:** Faza 1. Može da se radi paralelno sa Fazom 2.

### 3.1. Definisanje trust nivoa

- [x] `config/governance.py` (ili `config/governance.json`):
  - [x] Definisati trust tier-ove (A, B, C, D) sa opisom i dozvolama.
  - [x] Mapirati agente na trust tier po default-u (svi novi agenti počinju na Tier A).
  - [x] Definisati dozvoljene operacije po tier-u:
    - [x] Tier A: čitanje fajlova, analiza, generisanje izveštaja.
    - [x] Tier B: sve od A + predlaganje patch-eva (draft mode).
    - [x] Tier C: sve od B + auto-apply na feature branch (ne main).
    - [x] Tier D: zahteva ljudski review — merge u main, security promene, produkcija.

### 3.2. Enforcement sloj

- [x] `core/governance.py` — Governance modul:
  - [x] `check_permission(agent: Agent, action: str, target: str) -> PermissionResult`.
  - [x] `PermissionResult`: allowed (bool), reason (str), required_tier (str).
  - [x] Blokira nedozvoljene akcije i vraća jasan "POLICY_VIOLATION" rezultat umesto da tiho padne.

- [x] Ugraditi governance proveru u:
  - [x] `GlobalDirector` — pre nego što delegira task na context.
  - [x] `BoundedContext.execute()` — pre nego što agent izvrši task.

### 3.3. Consensus (V1 — jednostavan)

**Napomena:** Consensus u V1 je **opcionalan**. Implementirati samo ako ostane vremena u fazi. Osnovni governance (3.1 + 3.2) je prioritet.

- [ ] `core/consensus.py` — ConsensusAgent (V1): *(odloženo — opcionalno per specifikacija)*
  - [ ] Pokreće isti task na 2 agenta (ili 2 nezavisna LLM run-a).
  - [ ] Upoređuje rezultate — ako se slažu, vraća rezultat; ako ne, eskalira na review.

- [ ] `core/coherence.py` — CoherenceChecker (V1): *(odloženo — opcionalno per specifikacija)*
  - [ ] Proverava predlog protiv liste basic policy-ja (hardkodirano u V1).
  - [ ] Npr.: ne briši logove, ne menjaj security-sensitive kod, ne commituj na main.

### 3.4. Deliverables

- [x] `config/governance.py`, `core/governance.py` — implementirani i testirani.
- [x] Governance ugrađen u Director i Context flow.
- [x] Unit testovi za permission checking (dozvoljeno/blokirano scenarija).
- [x] Izveštaj u `docs/TEAM/REPORTS/REPORT_<datum>_FAZA3.md`.

### Kriterijum prihvatanja Faze 3

- Tier A agent ne može da napravi patch (samo analizu).
- Tier B agent može da napravi draft ali ne auto-apply.
- Tier C agent može auto-apply ali samo na feature branch.
- Policy violation se jasno loguje i vraća kao greška.
- Svi testovi prolaze.

---

## Faza 4 — ReasoningBank i Dream Cycles

**Cilj:** Dati swarmu pamćenje — da uči iz prethodnih zadataka.
**Prioritet:** SREDNJI.
**Procena:** 2-3 radna dana.
**Zavisi od:** Faza 1. Može da se radi paralelno sa Fazom 2 i 3.

### 4.1. ReasoningBank V1 (fajl-baziran)

- [x] Kreirati `reasoning/bank/` direktorijum.

- [x] `reasoning/bank.py` — ReasoningBank modul:
  - [x] Format zapisa (JSONL fajl `reasoning/bank/entries.jsonl`):
    - [x] task_id, timestamp, project, domain (bounded context name), task_type.
    - [x] description (kratak opis zadatka).
    - [x] decisions (lista ključnih odluka).
    - [x] outcome: success / failed / partial.
    - [x] lessons (lista od 1-3 kratke rečenice).
  - [x] `log_entry(task_result: TaskResult, lessons: list[str])` — upis.
  - [x] `search(project=None, domain=None, task_type=None, query=None) -> list[Entry]` — pretraga.
  - [x] `recent(n=10) -> list[Entry]` — poslednjih N zapisa.

- [x] Integrisati u GlobalDirector:
  - [x] Nakon svakog završenog taska, Director poziva `log_entry()`.
  - [x] Pre planiranja novog taska, Director poziva `search()` za relevantne lekcije i uključuje ih u prompt.

### 4.2. Dream cycles (periodično učenje)

- [x] `reasoning/dream_cycle.py` — skripta koja:
  - [x] Čita zapise iz ReasoningBank-a za dati period (npr. poslednih 7 dana) ili projekat.
  - [x] Koristi LLM (tier 2) da generiše sažete lekcije i preporuke.
  - [x] Upisuje ih u `reasoning/lessons/<project>.md` ili generalni `reasoning/lessons/GLOBAL.md`.

- [x] Definisati kako Director koristi lekcije:
  - [x] Pre planiranja, učitava `reasoning/lessons/<project>.md` ako postoji.
  - [x] Lekcije se dodaju kao kontekst u LLM prompt.

### 4.3. Deliverables

- [x] `reasoning/bank.py`, `reasoning/dream_cycle.py` — implementirani i testirani.
- [x] ReasoningBank integrisan u GlobalDirector flow.
- [x] Unit testovi za log/search/recent.
- [x] Izveštaj u `docs/TEAM/REPORTS/REPORT_<datum>_FAZA4.md`.

### Kriterijum prihvatanja Faze 4

- Nakon izvršenog taska, zapis postoji u `entries.jsonl`.
- `search()` vraća relevantne rezultate po projektu i domenu.
- Dream cycle skripta generiše čitljive lekcije.
- Svi testovi prolaze.

---

## Faza 5 — CLI i Developer UX

**Cilj:** Napraviti korisnički interfejs za rad sa swarm-om.
**Prioritet:** NAJVIŠI — direktiva PD-a (`DIRECTIVE_2026-02-25_prioritet-cli-faza5.md`).
**Procena:** 2-3 radna dana.
**Zavisi od:** Faza 1 i Faza 2.

### Tehničke smernice od DD-a (DECISIONS.md 2026-02-25)

- **Entrypoint:** `cli/main.py` — koristiti `argparse` (stdlib), bez eksternih paketa.
- **Arhitektura:** CLI je tanak sloj — instancira `GlobalDirector` sa 3 konteksta, prosleđuje task, formatira output. Nikakva business logika u CLI-ju.
- **LLM pozivi:** `noop_llm_call` za testove, `default_llm_call` za pravu upotrebu. Izbor preko `--dry-run` flaga ili env varijable.
- **Output:** Default human-readable. `--json` za mašinski čitljiv JSON (`json.dumps` sa indent).
- **`swarm history`:** Stub u Fazi 5 — ispisuje poruku da ReasoningBank nije konfigurisan. Prava implementacija u Fazi 4.
- **`swarm status`:** Prikazuje kontekste, agente (ime, tier, tipovi) i model tier konfiguraciju. Ne zahteva WS konekciju u V1.
- **Testovi:** `tests/test_cli.py` — smoke testovi za svaku komandu. Proveriti exit code, format, `--json` parsability.

### 5.1. Osnovni CLI

- [x] `cli/main.py` — Python entrypoint (`python -m cli.main` ili `swarm` alias):
  - [x] `swarm plan "opis zadatka"` → poziva GlobalDirector, ispisuje plan + subtasks.
  - [x] `swarm run "opis zadatka"` → poziva GlobalDirector, izvršava ceo flow, ispisuje rezultat.
  - [x] `swarm analyze <path>` → poziva code-understanding context.
  - [x] `swarm status` → prikazuje registrovane agente, connected workere, poslednje taskove.
  - [x] `swarm history [--project X] [--last N]` → ReasoningBank pretraga. **Napomena:** U Fazi 5 ovo je stub — ispisuje poruku da ReasoningBank nije konfigurisan. Prava implementacija dolazi u Fazi 4.

- [x] Output format:
  - [x] Default: human-readable (boje, formatiran tekst).
  - [x] `--json` flag: mašinski čitljiv JSON.

### 5.2. Integracija sa Claude Code

- [x] Napisati `docs/TEAM/CLAUDE_CODE_INTEGRATION.md`:
  - [x] Uputstvo kako pokrenuti swarm iz Claude Code sesije.
  - [x] Primer CLAUDE.md direktive koja kaže agentu da koristi swarm za složene zadatke.
  - [x] Primer prompt-a za Claude Code: "Ti si ai-software-swarm director za projekat X".

### 5.3. Deliverables

- [x] `cli/main.py` sa svim komandama.
- [x] `docs/TEAM/CLAUDE_CODE_INTEGRATION.md`.
- [x] Smoke testovi za CLI komande.
- [x] Izveštaj u `docs/TEAM/REPORTS/REPORT_<datum>_FAZA5.md`.

### Kriterijum prihvatanja Faze 5

- `swarm plan "dodaj feature X"` vraća strukturiran plan.
- `swarm run "analiziraj repo Y"` izvršava ceo flow i vraća rezultat.
- `swarm status` prikazuje stanje sistema.
- `--json` flag radi na svim komandama.
- Svi testovi prolaze.

---

## Faza 6 — Hardening, evaluacija i iteracija

**Cilj:** Stabilizovati sistem, uvesti metrike, pripremiti za svakodnevnu upotrebu.
**Prioritet:** NIZAK (ali obavezan pre "produkcije").
**Procena:** 2-3 radna dana.
**Zavisi od:** Sve prethodne faze.

### 6.1. Logovanje

- [x] Uvesti strukturirano logovanje za:
  - [x] Sve odluke GlobalDirector-a (task decomposition, context routing).
  - [x] Izbor modela (tier) — iz model_router loga.
  - [x] Governance blokade (policy violations).
  - [x] Trajanje svakog taska i subtaska.

- [x] Log format: JSONL fajl `logs/swarm_decisions.jsonl`.

### 6.2. Metrike

- [x] `scripts/swarm_metrics.py` — skripta za analizu:
  - [x] Prosečno vreme po tipu taska.
  - [x] Broj iteracija do uspeha.
  - [x] Koliko ljudskih intervencija je bilo potrebno (Tier D eskalacije).
  - [x] Učestalost policy violation-a.
  - [x] Distribucija po model tier-u (koliko ide na tier 1/2/3).

### 6.3. Infrastrukturni dug (iz MVP-a)

**Napomena:** Ovi taskovi su nasleđeni iz MVP faze. Ne blokiraju gore navedene faze ali ih treba rešiti pre intenzivne upotrebe.

- [x] PING/PONG keepalive za WS konekcije (server + worker).
- [x] Task persistence — sačuvati taskove/rezultate na disk (ne samo in-memory).
- [x] Capability registracija workera u HELLO poruci.
- [ ] Minimalni task queue za slučaj kad worker nije dostupan.
- [ ] Broadcasting: slanje taska bilo kom slobodnom workeru (load-balancing).

### 6.4. Deliverables

- [x] Logovanje aktivno u svim modulima.
- [x] `scripts/swarm_metrics.py` funkcionalan.
- [x] Bar 3 infrastrukturna duga rešena (PING/PONG, persistence, capabilities).
- [x] Izveštaj u `docs/TEAM/REPORTS/REPORT_<datum>_FAZA6.md`.

### Kriterijum prihvatanja Faze 6

- Svaka odluka sistema je logovana i čitljiva.
- Metrike se mogu generisati jednom komandom.
- Sistem je stabilan za svakodnevnu upotrebu (keepalive, persistence).
- Svi testovi prolaze.

---

## Napomene za tim

- Ovo je **V1 backlog**: nije sveto pismo. Kako budemo implementirali sistem na konkretnom kodu, neke stvari će se prelomiti drugačije.
- **Pitajte u izveštaju** ako naiđete na dilemu — direktor razvoja će dati smer na review-u.
- Ne ciljati "savršenu" arhitekturu u prvom prolazu — važnije je da imamo:
  - jasan Director sloj koji radi,
  - minimalni governance + routing,
  - mesto gde se pamte iskustva (ReasoningBank).
- Svaki veći korak treba da dođe sa kratkom dokumentacijom (README ili komentar u `DEVELOPMENT_DIRECTOR.md` / `LESSONS.md`) kako bi swarm i ljudi imali zajedničko razumevanje sistema.
- **Redosled je bitan.** Faza 0 → Faza 1 → ostalo. Ne preskačite.
- **Minimalni patch princip.** Ako nešto radi — ne dirajte ga "usput". Fokus na deliverables tekuće faze.
