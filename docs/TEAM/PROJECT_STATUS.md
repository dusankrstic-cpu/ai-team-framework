# PROJECT_STATUS.md — Stanje projekta ai-software-swarm

**Poslednje ažuriranje:** 2026-02-25 (PD sesija #1, ažuriranje #2 — V1 kompletiran)

### Vlasništvo sekcija

| Sekcija | Ko piše | Napomena |
|---------|---------|----------|
| 1. O projektu | Direktor projekta | Retko se menja |
| 2. Trenutna faza (tabela + graf) | **Direktor razvoja** | Ažurira nakon svakog review-a |
| 3. Šta je završeno | Direktor projekta | Na osnovu izveštaja DD-a |
| 4. Šta je u toku | Direktor projekta | Na osnovu izveštaja DD-a |
| 5. Otvorena pitanja i rizici | Direktor projekta | Strateški rizici |
| 6. Milestone-i | Direktor projekta | Strateške odluke |
| 7. Tim i uloge | Direktor projekta | Retko se menja |
| 8. Strateški log | **Samo direktor projekta** | Trajna memorija PD-a |
| 9. Ključni dokumenti | Direktor projekta | Retko se menja |

**Pravilo:** Direktor razvoja **nikada** ne piše u sekcije 3–9. Direktor projekta **nikada** ne piše u sekciju 2 (tabela faza). Ovo sprečava konflikte kada dve uloge ažuriraju isti fajl.

---

## 1. O projektu

**ai-software-swarm** je interni agentni roj za softverski razvoj. Radi u paru sa Dušanom i Claude Code-om. Cilj je praktičan sistem koji ubrzava razvoj, daje konzistentne predloge, smanjuje kognitivno opterećenje i uči iz iskustva.

**Vlasnik:** Dušan Krstić, SYMAPPSYS DOO, Novi Sad
**Repo:** `git@github.com:dusankrstic-cpu/ai-software-swarm.git`
**Runtime:** Python 3.12+, jedina zavisnost: `websockets>=12.0`
**VM:** kosarka (192.168.1.213) — remote worker

---

## 2. Trenutna faza

| Faza | Naziv | Status |
|------|-------|--------|
| Faza 0 | Priprema i okvir | **ZAVRŠENA** — review prihvaćen |
| Faza 1 | Bounded Contexts + Director sloj | **ZAVRŠENA** — review prihvaćen |
| Faza 2 | Model Routing | **ZAVRŠENA** — review prihvaćen |
| Faza 3 | Governance i Trust Tiers | **ZAVRŠENA** — review prihvaćen |
| Faza 4 | ReasoningBank i Dream Cycles | **ZAVRŠENA** — review prihvaćen (176 testova ukupno) |
| Faza 5 | CLI i Developer UX | **ZAVRŠENA** — review prihvaćen (134 testova ukupno) |
| Faza 6 | Hardening | **ZAVRŠENA** — review prihvaćen (210 testova ukupno) |

### Graf zavisnosti

```
Faza 0 ✓ ──►  Faza 1 ✓ ──►  Faza 2 ✓  ──►  Faza 5 ✓
                 │              │
                 │              ▼
                 │          Faza 4 ✓
                 │              │
                 ▼              ▼
              Faza 3 ✓  ──►  Faza 6 ✓

Legenda: ✓ završeno  ● u toku  ○ čeka
```

---

## 3. Šta je završeno

### MVP Infrastrukturni sloj (pre projekta)

- WebSocket server sa agent registrom i TASK/RESULT routing
- Worker sa 4 executora (shell.run, python.run, llm.call, generic)
- Protocol dataclass-ovi (SwarmMessage, TaskPayload, ResultPayload)
- Controller CLI i programski dispatcher
- 19 testova (4 E2E + 15 unit) — svi prolaze
- Live testirano na VM kosarka

### Faza 0 — Priprema i okvir (2026-02-25)

- 10 novih direktorijuma kreirano (`core/`, `contexts/`, `reasoning/`, `cli/`, `config/` sa pod-paketima)
- Svi sa `__init__.py` i `README.md`
- `BRIDGE.md` — dokument o vezi infrastrukturnog i orkestracionog sloja (300 linija)
- Review: PRIHVAĆENO od strane direktora razvoja

### Faza 1 — Bounded Contexts i Director sloj (2026-02-25)

- Core apstrakcije: `SwarmTask`, `TaskResult`, `Agent`, `BoundedContext`, `GlobalDirector`
- 3 bounded contexts sa po jednim agentom: `PlannerAgent`, `CodeAnalyzerAgent`, `ImplementerAgent`
- Factory pattern za DI (`create_*_context(llm_call)`)
- Output chaining kroz `metadata["previous_output"]`
- LLMCallable Protocol + `noop_llm_call` za testabilnost
- 25 novih testova (ukupno 44) — svi prolaze
- Review: PRIHVAĆENO od strane direktora razvoja

### Faza 2 — Model Routing (2026-02-25)

- Centralizovani `select_tier()` router — pure function, bez stanja osim audit loga
- `config/models.py` sa 3 tier-a (fast/balanced/deep) i `ModelTier` dataclass
- `Agent.resolve_llm_call()` — agenti ne moraju da znaju za tiere
- Metadata i env override mehanizmi za debugging i dev/prod
- 20 novih testova (ukupno 64) — svi prolaze
- Review: PRIHVAĆENO od strane direktora razvoja

### Faza 3 — Governance i Trust Tiers (2026-02-25)

- Trust tier sistem (A/B/C/D) sa MINIMUM_TIER mapiranjem po task tipu
- Defense-in-depth enforcement na dva nivoa (BoundedContext + GlobalDirector)
- `config/governance.py` i `core/governance.py` — PermissionResult, GovernanceDecision
- Agent trust dodele: CodeAnalyzer=A, Planner=B, Implementer=D
- Consensus i CoherenceChecker odloženi (opcionalni za V1)
- 46 novih testova (ukupno 110) — svi prolaze
- Review: PRIHVAĆENO od strane direktora razvoja

### Faza 5 — CLI i Developer UX (2026-02-25)

- CLI entrypoint (`cli/main.py`) sa 5 komandi: `swarm plan`, `run`, `analyze`, `status`, `history`
- `--json` flag za mašinski čitljiv output, `--dry-run` / `SWARM_DRY_RUN=1` za testiranje bez LLM-a
- CLI kao tanak sloj — nula business logike, samo argparse + Director + formatiranje
- `swarm run` demonstrira end-to-end flow: PLAN → ANALYZE → IMPLEMENT
- `docs/TEAM/CLAUDE_CODE_INTEGRATION.md` — uputstvo za korišćenje iz Claude Code-a
- 24 nova testa (ukupno 134) — svi prolaze
- Review: PRIHVAĆENO od strane direktora razvoja

### Faza 4 — ReasoningBank i Dream Cycles (2026-02-25)

- `ReasoningBank` sa JSONL storage: `log_entry()`, `search()`, `recent()`, `count()`
- Composable filteri za pretragu (project, domain, task_type, query)
- Dream cycle mehanizam: čita zapise → LLM generiše lekcije → upisuje u `reasoning/lessons/`
- Director integracija: `_enrich_with_lessons()` pre planiranja, `_log_to_bank()` nakon izvršenja
- CLI `swarm history` povezan sa pravim ReasoningBank-om (zamenjen stub iz Faze 5)
- 42 nova testa (ukupno 176) — svi prolaze
- Review: PRIHVAĆENO od strane direktora razvoja

### Faza 6 — Hardening (2026-02-25)

- Decision log persistence: `flush_to_jsonl()` persistira Director/Routing/Governance odluke u `logs/swarm_decisions.jsonl`
- Metrike skripta (`scripts/swarm_metrics.py`): tier distribucija, governance violations, bank statistike, prosečno vreme
- PING/PONG keepalive: server šalje PING svakih 30s, timeout 10s, worker odgovara PONG-om
- Task persistence: append u `logs/swarm_task_results.jsonl`, `load_persisted_results()` za crash recovery
- Capability registracija: HELLO šalje listu executora, server čuva i vraća u STATUS
- Director pipeline finalno 7 koraka: enrich → analyze → decompose → execute → aggregate → log_to_bank → flush_decisions
- 3 od 5 infrastrukturnih dugova rešena; broadcasting i task queue van scope-a V1
- 34 nova testa (ukupno 210) — svi prolaze
- Review: PRIHVAĆENO od strane direktora razvoja

---

## 4. Šta je u toku

**V1 je kompletiran.** Sve faze (0–6) su završene. Nema aktivnih razvojnih zadataka.

### Kandidati za V2

- Testiranje V1 na realnim zadacima (validacija pre širenja)
- V2 bounded contexts: architecture-design, refactoring-improvement, testing-and-quality, documentation-and-communication, ops-and-governance
- Consensus / CoherenceChecker (odložen iz Faze 3)
- ReasoningBank rotacija i dream cycle kao cron job
- Broadcasting / task queue za multi-worker scenarije

---

## 5. Otvorena pitanja i rizici

| Rizik | Verovatnoća | Uticaj | Mitigacija | Status |
|-------|-------------|--------|------------|--------|
| Vizija previše ambiciozna (8 konteksta) | Srednja | Visok | Iterativni pristup — samo 3 konteksta u V1 | **Zatvoren** — V1 sa 3 konteksta kompletiran |
| Infrastrukturni dug (PING/PONG, persistence) | Niska | Srednji | Faza 6 | **Zatvoren** — 3/5 rešeno, preostala 2 van scope-a V1 |
| LLM integracija na VM-u (llm.call) | Srednja | Srednji | Kod spreman, čeka aktivno testiranje | **Otvoren** — V1 testiran sa noop_llm_call, realan LLM čeka |
| CLI upotrebljivost (Faza 5) | Srednja | Visok | Faza 5 | **Zatvoren** — 5 komandi funkcionalno |
| Consensus/Coherence odloženi | Niska | Nizak | Dodaje se po potrebi | Prihvaćen rizik — nema hitnosti |
| V1 netestiran na realnim zadacima | Srednja | Visok | Prva upotreba sa pravim LLM-om i projektom | **NOV** — svi testovi koriste noop_llm_call |
| Broadcasting / task queue nedostaju | Niska | Nizak | Nije potrebno dok je 1 worker | Prihvaćen rizik |

---

## 6. Milestone-i

### V1 — kompletiran 2026-02-25

| Milestone | Opis | Datum | Status |
|-----------|------|-------|--------|
| M1 — Skeleton | Direktorijumi + BRIDGE.md | 2026-02-25 | **DONE** |
| M2 — Director radi | GlobalDirector + 3 contexta, end-to-end flow | 2026-02-25 | **DONE** |
| M3 — Model routing | Centralni router, tier-based izbor | 2026-02-25 | **DONE** |
| M4 — Governance | Trust tiers, permission enforcement | 2026-02-25 | **DONE** |
| M5 — CLI | `swarm plan` / `swarm run` funkcionalni | 2026-02-25 | **DONE** |
| M6 — Pamćenje | ReasoningBank + dream cycles | 2026-02-25 | **DONE** |
| M7 — Production-ready | Hardening, metrike, infrastrukturni dug | 2026-02-25 | **DONE** |

**Svi V1 milestone-i završeni u jednom danu. 210 testova, svi prolaze.**

### V2 — TBD

| Milestone | Opis | Rok | Status |
|-----------|------|-----|--------|
| M8 — Realna validacija | Testiranje V1 na pravom projektu sa LLM-om | TBD | Čeka stratešku odluku |
| M9 — V2 konteksti | Novi bounded contexts (architecture, refactoring, testing...) | TBD | Čeka M8 |
| M10 — Skaliranje | Broadcasting, task queue, multi-worker | TBD | Čeka M8 |

---

## 7. Tim i uloge

| Uloga | MCP fajl | Odgovornost |
|-------|----------|-------------|
| Direktor projekta | `PROJECT_DIRECTOR.md` | Strategija, milestone-i, direktive |
| Direktor razvoja | `DEVELOPMENT_DIRECTOR.md` | Arhitektura, review, TODO.md |
| Razvojni tim | `DEVELOPMENT_TEAM.md` | Implementacija, testovi, izveštaji |

---

## 8. Strateški log — odluke direktora projekta

Hronološki zapis strateških odluka. Najnovije na vrhu. Ovo je **trajna memorija** direktora projekta.

### 2026-02-25 — PROCENA: V1 kompletiran — svih 7 faza završeno

**Kontekst:** DD podneo izveštaje za Faze 5, 4 i 6. Sve review-ovane i prihvaćene. Ukupno 210 testova, svi prolaze. Ceo V1 scope kompletiran u jednom danu: orkestracioni sloj (core, routing, governance), pamćenje (ReasoningBank, dream cycles), korisničko iskustvo (CLI, Claude Code integracija) i hardening (decision log, metrike, PING/PONG, persistence, capabilities).
**Odluka:** V1 je završen. Ažuriram PROJECT_STATUS.md sa finalnim stanjem. Direktiva DIRECTIVE_2026-02-25_prioritet-cli-faza5.md → ZAVRŠENA. Definišem V2 milestone-e (M8–M10) sa TBD rokovima.
**Obrazloženje:** Projekat je ispunio sve planirane deliverables. Sledeći strateški korak je validacija na realnom zadatku — svi testovi koriste noop_llm_call, sistem još nije testiran sa pravim LLM-om i pravim projektom. Ovo je sada najveći rizik.
**Direktiva:** NE — čekam Dušanov input za smer V2.

### 2026-02-25 — PROCENA: Prva sesija PD-a — stanje projekta

**Kontekst:** Prva sesija direktora projekta. Projekat pokrenut i 4 faze završene istog dana (25.02.). Ukupno 110 testova, svi prolaze. Orkestracioni kostur (core, routing, governance) kompletiran. Dokumentacija je bila zastarela — PROJECT_STATUS.md je pokazivao Fazu 1 kao "u toku" dok su Faze 1–3 već završene.
**Odluka:** Ažurirao sekcije 3–8 sa stvarnim stanjem. Ažurirao milestone-e M2–M4 kao DONE. Postavio okvirne rokove za M5–M7.
**Obrazloženje:** Bez ažurne dokumentacije nema transparentnosti ni kontinuiteta između sesija.
**Direktiva:** NE

### 2026-02-25 — ODLUKA: CLI (Faza 5) pre ReasoningBank-a (Faza 4)

**Kontekst:** Obe faze su spremne za rad (zavisnosti ispunjene). DD je predložio paralelni rad na oba. Strateško pitanje: šta ima prioritet?
**Odluka:** Faza 5 (CLI) ima prioritet. Faza 4 (ReasoningBank) može paralelno ili nakon.
**Obrazloženje:** CLI (`swarm plan`, `swarm run`) je prvi put kad sistem postaje upotrebljiv za Dušana. Bez CLI-ja, ceo orkestracioni sloj je "mrtav kod" — postoji ali se ne koristi. ReasoningBank je optimizacija koja dodaje vrednost tek kad sistem već ima korisnike. Prioritet: upotrebljivost pre optimizacije.
**Direktiva:** DA — `DIRECTIVE_2026-02-25_prioritet-cli-faza5.md`

---

## 9. Ključni dokumenti

| Dokument | Svrha |
|----------|-------|
| `docs/TEAM/PROJECT_STATUS.md` | Ovaj fajl — stanje projekta + strateški log |
| `docs/TEAM/ARCHITECTURE_VISION.md` | Tehnička vizija i arhitektura |
| `docs/TEAM/DECISIONS.md` | Tehničke odluke direktora razvoja |
| `docs/TEAM/TODO.md` | Razvojni backlog po fazama |
| `docs/TEAM/BRIDGE.md` | Veza infrastrukturnog i orkestracionog sloja |
| `docs/TEAM/REPORTS/` | Izveštaji razvojnog tima |
| `docs/TEAM/DIRECTIVES/` | Strateške direktive direktora projekta |
