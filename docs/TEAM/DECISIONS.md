# DECISIONS.md — Log tehničkih odluka direktora razvoja

Ovaj fajl je **trajna memorija** direktora razvoja. Svaka tehnička odluka, review i smernica se ovde beleži hronološki (najnovije na vrhu). Čitaj ga na početku svake sesije da osiguraš konzistentnost.

---

### 2026-02-25 — REVIEW: Faza 6 — Hardening, evaluacija i iteracija

**Kontekst:** Tim podneo izveštaj `REPORT_2026-02-25_FAZA6.md`. Implementiran decision log persistence (JSONL), metrike skripta, i tri infrastrukturne popravke (PING/PONG, task persistence, capability registracija).
**Odluka:** PRIHVAĆENO. Svi kriterijumi prihvatanja ispunjeni, 210/210 testova prolaze, orkestracioni sloj i reasoning netaknuti.
**Napomene:**
- DD smernica ispoštovana: `decision_log.py` persistira postojeće in-memory logove (DirectorDecision, RoutingDecision, GovernanceDecision) — ne duplicira ih.
- `flush_to_jsonl()` čisti in-memory logove nakon persistiranja — sprečava dupliranje zapisa.
- `compute_metrics()` je pure function — prima decisions + bank_entries, vraća dict sa 6 kategorija metrika.
- Director pipeline proširen na 7 koraka: enrich → analyze → decompose → execute → aggregate → log_to_bank → flush_decisions.
- Infrastrukturni dug: 3 od 5 stavki rešeno (PING/PONG, task persistence, capabilities). Broadcasting i task queue ostaju van scope-a V1 — prihvatljivo.
- PING/PONG: server šalje PING svakih 30s, timeout 10s, worker odgovara PONG-om. Cancel u finally bloku.
- Task persistence: append u `logs/swarm_task_results.jsonl`, `load_persisted_results()` za crash recovery.
- Capabilities: HELLO šalje listu executora, server čuva u `agent_capabilities` dict, briše pri disconnect-u.
- `swarm/protocol.py` netaknut — PING/PONG MessageType je već bio definisan u MVP-u.
- 34 nova testa u 3 fajla. Test count korektan (176 + 34 = 210).

---

### 2026-02-25 — REVIEW: Faza 4 — ReasoningBank i Dream Cycles

**Kontekst:** Tim podneo izveštaj `REPORT_2026-02-25_FAZA4.md`. Implementiran ReasoningBank (JSONL storage sa log/search/recent/count), dream cycle mehanizam za generisanje lekcija, i integracija sa GlobalDirector-om i CLI-jem.
**Odluka:** PRIHVAĆENO. Svi kriterijumi prihvatanja ispunjeni, 176/176 testova prolaze, infrastruktura i orkestracioni sloj netaknuti.
**Napomene:**
- Smernica iz DECISIONS.md ispoštovana: ReasoningBank povezan sa Director-om (log_entry + search/enrich) i CLI-jem (history stub → prava implementacija).
- `BankEntry` dataclass sa `to_dict()`/`from_dict()` roundtrip — čist pattern.
- `search()` sa composable filterima (project, domain, task_type, query) — case-insensitive za project.
- Circular import rešen lazy importom u `_enrich_with_lessons()` i `Any` tipom za `reasoning_bank` field — standardan Python pattern.
- Director integracija: `_enrich_with_lessons()` pre planiranja (učitava dream cycle lekcije + nedavne bank zapise), `_log_to_bank()` nakon izvršenja. Oba opcionalna (noop ako bank=None) — backward compatible.
- `handle()` pipeline proširen na 6 koraka: enrich → analyze → decompose → execute → aggregate → log.
- CLI `cmd_history()` sada koristi pravi ReasoningBank umesto stub-a. Human-readable i JSON format.
- Dream cycle sa CLI entrypoint-om (`python -m reasoning.dream_cycle`) — bonus funkcionalnost.
- 42 nova testa u 3 fajla: test_reasoning_bank.py (24), test_dream_cycle.py (9), test_reasoning_integration.py (9).
- Test count u izveštaju korektan (134 + 42 = 176).

---

### 2026-02-25 — SMERNICA: Naredna faza — Faza 6 (Hardening)

**Kontekst:** Faza 4 prihvaćena. Sve faze 0-5 završene. Jedino preostaje Faza 6 (Hardening).
**Odluka:** Tim može da krene na Fazu 6. Ključni fokus: strukturirano logovanje (JSONL), metrike skripta, i infrastrukturni dug (PING/PONG, persistence, capabilities).
**Obrazloženje:** Ceo orkestracioni stek je kompletiran (core, routing, governance, reasoning, CLI). Poslednji korak je stabilizacija za svakodnevnu upotrebu.
**Preporuke za Fazu 6:**
- ReasoningBank `entries.jsonl` rotacija — razmotriti pristup sličan `rotate_logs.py` iz Savka projekta.
- Dream cycle kao cron job (dnevno ili nedeljno).
- Logovanje: iskoristiti postojeći `DirectorDecision` audit trail i `RoutingDecision` log — ne duplicirati, već ih samo persistirati u JSONL.

---

### 2026-02-25 — REVIEW: Faza 5 — CLI i Developer UX

**Kontekst:** Tim podneo izveštaj `REPORT_2026-02-25_FAZA5.md`. Implementiran CLI entrypoint (`cli/main.py`) sa 5 komandi, `--json` i `--dry-run` flagovima, i dokumentacija za Claude Code integraciju.
**Odluka:** PRIHVAĆENO. Svi kriterijumi prihvatanja ispunjeni, 134/134 testova prolaze, infrastruktura i orkestracioni sloj netaknuti.
**Napomene:**
- Svih 8 tehničkih smernica iz DECISIONS.md ispoštovano.
- CLI je zaista tanak sloj — nula business logike, samo argparse + director instantiation + output formatiranje.
- Dual test pristup (subprocess + direktan main() poziv) — temeljno testiranje.
- JSON parsability verifikovana za svih 5 komandi.
- `swarm history` je stub per moja odluka — spreman za povezivanje sa ReasoningBank-om u Fazi 4.
- `swarm run` koristi TaskType.IMPLEMENT → aktivira puni flow (PLAN → ANALYZE → IMPLEMENT) — demonstrira end-to-end orkestraciju.
- `CLAUDE_CODE_INTEGRATION.md` — kompletna dokumentacija sa primerom CLAUDE.md direktive i ASCII dijagramom.
- Test count korektan u izveštaju (110 + 24 = 134) — za razliku od Faze 3.

---

### 2026-02-25 — SMERNICA: Naredna faza — Faza 4 (ReasoningBank i Dream Cycles)

**Kontekst:** Faza 5 prihvaćena. Preostaju Faza 4 i Faza 6. Faza 4 je sledeća po grafu zavisnosti.
**Odluka:** Tim može da krene na Fazu 4. Ključna integracija: povezati ReasoningBank sa `GlobalDirector` (log_entry nakon svakog taska, search pre planiranja) i sa CLI (`swarm history` stub → prava implementacija).
**Obrazloženje:** Sistem je sada upotrebljiv (CLI radi). Sledeći korak je dodati pamćenje da bi se kvalitet poboljšavao sa iskustvom.

---

### 2026-02-25 — ODLUKA: Obrada direktive — Faza 5 (CLI) pre Faze 4 (ReasoningBank)

**Kontekst:** Direktor projekta izdao direktivu `DIRECTIVE_2026-02-25_prioritet-cli-faza5.md` — Faza 5 ima prioritet nad Fazom 4. Obe faze su tehnički spremne (zavisnosti ispunjene).
**Odluka:** Prihvatam direktivu. Ovo je strateška odluka (prioritizacija) — domen PD-a. Tehnički nema prepreka.
**Obrazloženje:** CLI je prvi korisnički interfejs sistema. Bez njega orkestracioni sloj je neupotrebljiv u praksi. PD-ov argument "upotrebljivost pre optimizacije" je ispravan.

---

### 2026-02-25 — ODLUKA: `swarm history` u Fazi 5 bez ReasoningBank-a

**Kontekst:** TODO.md 5.1 definiše `swarm history [--project X] [--last N]` koja zavisi od ReasoningBank-a (Faza 4). PD je ostavio tehničku odluku meni: da li uvući deo Faze 4 u Fazu 5.
**Odluka:** NE uvlačiti Faza 4 kod u Fazu 5. Komanda `swarm history` će postojati u CLI-ju ali će ispisati poruku da ReasoningBank nije konfigurisan. Kad Faza 4 bude gotova, history se samo poveže.
**Obrazloženje:** Čista separacija faza. Mešanje scope-ova donosi nepotreban rizik i komplikuje review. Iste komande, samo sa stubom za history.

---

### 2026-02-25 — SMERNICA: Tehničke smernice za tim — Faza 5 (CLI)

**Kontekst:** Tim kreće na Fazu 5. Ovo su tehničke smernice za implementaciju.
**Odluka:**
1. **Entrypoint:** `cli/main.py` — koristiti `argparse` (stdlib), ne uvoziti eksterne pakete.
2. **Arhitektura:** CLI je tanak sloj — instancira `GlobalDirector` sa 3 konteksta, prosleđuje task, formatira output. Nikakva business logika u CLI-ju.
3. **LLM pozivi:** Za lokalno testiranje koristiti `noop_llm_call`. Za pravu upotrebu `default_llm_call` (claude CLI). Izbor preko env varijable ili flaga.
4. **Output format:** Default human-readable (plain text sa strukturom). `--json` flag za mašinski čitljiv JSON (koristiti `json.dumps` sa indent).
5. **`swarm history`:** Stub — ispisuje poruku da ReasoningBank nije konfigurisan. Implementacija u Fazi 4.
6. **`swarm status`:** Prikazuje registrovane kontekste, agente (ime, tier, podržani tipovi), i model tier konfiguraciju. Ne zahteva WS konekciju u V1.
7. **Testovi:** `tests/test_cli.py` — smoke testovi za svaku komandu (subprocess ili direktan poziv). Proveriti exit code, format outputa, `--json` parsability.
8. **Claude Code integracija (5.2):** Napisati `docs/TEAM/CLAUDE_CODE_INTEGRATION.md` — uputstvo, primer CLAUDE.md direktive, primer prompta.
**Obrazloženje:** Minimalni CLI koji demonstrira ceo orkestracioni flow. Bez over-engineering-a.

---

### 2026-02-25 — REVIEW: Faza 3 — Governance i Trust Tiers

**Kontekst:** Tim podneo izveštaj `REPORT_2026-02-25_FAZA3.md`. Implementirani `config/governance.py` i `core/governance.py` sa trust tier sistemom (A/B/C/D) i defense-in-depth enforcement-om.
**Odluka:** PRIHVAĆENO. Svi kriterijumi prihvatanja ispunjeni, 110/110 testova prolaze, infrastruktura netaknuta.
**Napomene:**
- Defense in depth: governance provera na dva nivoa (BoundedContext.execute + GlobalDirector.execute_subtask) — dobro dizajnirano.
- MINIMUM_TIER kao single source of truth sa auto-generisanim TRUST_TIERS — elegantan pattern.
- Circular import izbegnut korišćenjem string ključeva umesto TaskType enum-a — pragmatično, dokumentovano, StrEnum garantuje kompatibilnost.
- Trust tier dodele ispravne: CodeAnalyzerAgent=A, PlannerAgent=B, ImplementerAgent=D.
- Consensus i CoherenceChecker nisu implementirani — prihvatljivo per TODO.md (označeni kao opcionalni).
- **Greška u izveštaju:** tim prijavio 91 testova (64+27), stvarni broj je 110 (64+46). test_governance.py ima 34 testa, ne 27. Dokumentaciona greška, ne kod.

---

### 2026-02-25 — REVIEW: Faza 2 — Model Routing ("TinyDancer" princip)

**Kontekst:** Tim podneo izveštaj `REPORT_2026-02-25_FAZA2.md`. Implementirani `config/models.py` i `core/model_router.py` sa centralizovanim izborom modela.
**Odluka:** PRIHVAĆENO. Svi kriterijumi prihvatanja ispunjeni, 64/64 testova prolaze, infrastruktura netaknuta.
**Napomene:**
- Router kao pure function (`select_tier()`) — čist, bez stanja osim audit loga.
- `Agent.resolve_llm_call()` elegantan bridge — agenti ne moraju da znaju za tiere.
- Metadata override (`task.metadata["model_tier"]`) za debugging i specijalne slučajeve.
- Env override za model_id (SWARM_MODEL_TIER1/2/3) — dobro za dev vs prod.
- Model ID-evi aktuelni: haiku-4-5, sonnet-4-6, opus-4-6.
- Sva routing pravila pokrivena testovima (20 novih testova).

---

### 2026-02-25 — REVIEW: Faza 1 — Bounded Contexts i Director sloj

**Kontekst:** Tim podneo izveštaj `REPORT_2026-02-25_FAZA1.md`. Implementiran orkestracioni sloj: 4 core modula, 3 agenta, 3 context factory-ja, 25 novih testova.
**Odluka:** PRIHVAĆENO. Svi kriterijumi prihvatanja ispunjeni, 44/44 testova prolaze, infrastruktura netaknuta.
**Napomene:**
- Redosled implementacije (task→agent→context→director) ispoštovan per moja smernica.
- SwarmTask ↔ TaskPayload konverzija kao metode na klasi — ispoštovano per moja odluka.
- GlobalDirector sinhroni (V1) — ispoštovano per moja odluka.
- Test struktura: 4 fajla umesto 2 (test_core_task, test_core_agent, test_core_context, test_director_integration) — prihvatljivo odstupanje, granularnije je bolje.
- Output chaining kroz `metadata["previous_output"]` — čist pattern za sekvencijalno izvršavanje.
- LLMCallable Protocol + noop_llm_call za DI — odlična testabilnost.
- _TASK_TYPE_FLOWS heuristike u directoru — jasna decomposition logika.
- Factory pattern `create_*_context(llm_call)` — konzistentan DI za sve kontekste.

---

### 2026-02-25 — SMERNICA: Naredne faze nakon review-a Faza 1-3

**Kontekst:** Sve tri faze (1, 2, 3) prihvaćene u jednom review ciklusu. Ukupno 110 testova, orkestracioni sloj kompletiran sa core apstrakcijama, model routing-om i governance-om.
**Odluka:** Sledeće faze po grafu zavisnosti su Faza 4 (ReasoningBank + Dream Cycles) i Faza 5 (CLI). Faza 4 i 5 mogu da se rade paralelno — Faza 4 zavisi samo od Faze 1, Faza 5 zavisi od Faze 1 i 2.
**Obrazloženje:** Orkestracioni kostur je sada kompletiran. Prioritet je dodati pamćenje (Faza 4) i korisnički interfejs (Faza 5) da bi sistem bio upotrebljiv u praksi.

---

### 2026-02-25 — REVIEW: Faza 0 — Priprema i okvir

**Kontekst:** Tim je podneo izveštaj `REPORT_2026-02-25_FAZA0.md`. Kreiran 21 fajl (10 direktorijuma sa __init__.py i README.md + BRIDGE.md).
**Odluka:** PRIHVAĆENO. Svi kriterijumi ispunjeni, 19 testova i dalje prolaze, nijedan postojeći fajl nije menjan.
**Napomene:**
- Tim je proaktivno kreirao `reasoning/bank/` i `reasoning/lessons/` — prihvaćeno jer su u specifikaciji za Fazu 4.
- Broj testova konzistentan (4 E2E + 15 unit = 19).
- BRIDGE.md izuzetan kvalitet (300 linija, 8 sekcija, ASCII dijagram, error putanje).

---

### 2026-02-25 — SMERNICA: Redosled implementacije za Fazu 1

**Kontekst:** Tim je predložio redosled za Fazu 1.
**Odluka:** Odobren redosled: `task.py → agent.py → context.py → director.py`. To je ispravna dependency chain — svaki modul zavisi od prethodnog.

---

### 2026-02-25 — ODLUKA: SwarmTask ↔ TaskPayload konverzija

**Kontekst:** Tim je pitao kako implementirati konverziju između orkestracionog SwarmTask i infrastrukturnog TaskPayload.
**Odluka:** Konverzija kao metode na klasi — `SwarmTask.to_task_payload()` i `@classmethod TaskResult.from_result_payload()`. Ne praviti poseban converter modul.
**Obrazloženje:** Jednostavnije, manje fajlova, konverzija je odgovornost samog objekta.

---

### 2026-02-25 — ODLUKA: GlobalDirector sync vs async

**Kontekst:** Arhitekturna odluka za prvu verziju GlobalDirector-a.
**Odluka:** GlobalDirector u V1 neka bude **sinhroni**. Async se dodaje kasnije kada bude trebalo paralelno izvršavanje konteksta.
**Obrazloženje:** Za početak je bitno da ceo flow proradi end-to-end. Async dodaje kompleksnost koja nije potrebna dok imamo samo sekvencijalno izvršavanje.

---

### 2026-02-25 — ODLUKA: Struktura testova za Fazu 1

**Kontekst:** Tim je predložio test fajlove za Fazu 1.
**Odluka:** Dva fajla: `tests/test_core.py` za unit testove core apstrakcija i `tests/test_director_integration.py` za integration test celog flow-a.
**Obrazloženje:** Razdvajanje unit od integration testova — jasna granularnost.
