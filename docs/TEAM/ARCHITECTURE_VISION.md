# ARCHITECTURE_VISION.md — Tehnička vizija ai-software-swarm

Ovaj dokument je **referenca za ceo tim** — svi ga čitaju, niko ga ne menja bez odobrenja direktora projekta i direktora razvoja zajedno. Sadrži arhitekturnu viziju, dizajn odluke i tehničke specifikacije sistema.

---

## 1. Vizija i ciljevi

**ai-software-swarm** je interni "agentni roj" (swarm) za razvoj softvera koji radi u paru sa Dušanom i Claude Code‑om. Cilj nije da napravimo generički AGI framework, nego **praktičan sistem** koji:

- ubrzava razvoj i refaktorisanje postojećih projekata,
- daje konzistentne, visoko‑kvalitetne predloge (kod, arhitektura, testovi),
- smanjuje kognitivno opterećenje (organizacija taskova, TODO, dokumentacija),
- uči iz svog iskustva (što više radimo sa swarm‑om, to je bolji),
- nikada ne pravi velike, rizične promene bez jasne kontrole i logovanja.

Inspiracija: **Agentic QE Fleet** (DDD bounded contexts, Queen Coordinator, model routing, ReasoningBank, consensus sloj), ali u domenu **software developmenta**, ne QA‑a.

### 1.1. Strateška odluka: iterativni pristup

Vizija definiše 8 bounded contexts, ali **ne gradimo svih 8 odjednom**. Prva iteracija fokusira se na **3 ključna konteksta**:

1. **planning-orchestrator** — bez njega nema orkestracije
2. **feature-implementation** — najčešći tip zadatka u praksi
3. **code-understanding** — preduslov za kvalitetnu implementaciju

Ostali konteksti se dodaju **tek kada prva trojka prorade i budu testirani na realnim zadacima**.


## 2. DDD i bounded contexts — kako delimo roj

Umesto jednog "mega‑agenta", swarm je podeljen na **domen pods** (bounded contexts). Svaki context ima:
- jasnu svrhu,
- svoje tipične ulazne zadatke,
- svoje agente i skill‑ove,
- svoje kriterijume uspeha.

### 2.1. Bounded contexts — V1 (prva iteracija, 3 konteksta)

1. **planning-orchestrator**
   - Svrha: prima high‑level zadatke (od Dušana ili spoljnog sistema) i pretvara ih u plan, raspodelu na druge kontekte, konsolidaciju rezultata.
   - Primer zadataka: "Dodaj support za X u projektu Y", "Refaktoriši modul Z", "Napravi onboarding dokumentaciju za projekat".

2. **code-understanding**
   - Svrha: razumevanje postojećeg koda i strukture projekta.
   - Zaduženja: mapiranje modula, identifikacija entrypoint‑ova, detekcija ključnih dependency‑a, generisanje sažetaka po fajlu/modulu.

3. **feature-implementation**
   - Svrha: generisanje konkretnih implementacija (kod + migracije + potrebne izmene).
   - Zaduženja: pisanje novih fajlova, dopuna postojećih, priprema PR‑ova/patch‑eva.

### 2.2. Bounded contexts — V2 (nakon stabilizacije V1)

4. **architecture-design**
   - Svrha: predlaganje i evaluacija arhitekture (moduli, granice, pattern‑i).

5. **refactoring-improvement**
   - Svrha: čišćenje i unapređenje postojećeg koda bez menjanja ponašanja.

6. **testing-and-quality**
   - Svrha: test strategija + generisanje testova + analiza pokrivenosti.

7. **documentation-and-communication**
   - Svrha: generisanje i održavanje dokumentacije + komunikacionih artefakata.

8. **ops-and-governance**
   - Svrha: policy, trust tiers, dozvole, logovanje, kontrola kvaliteta outputa.


## 3. Orkestracija — "Queen" / Director agent

### 3.1. Globalni Director

- Prima high‑level zadatke (od Dušana, CLI‑ja, ekosistema).
- Radi inicijalni **task framing**:
  - koji projekat, repo, domen, rizik;
  - koji output format, deadline, ograničenja.
- Deli zadatak na subtasks i dodeljuje ih odgovarajućim bounded contexts.
- Vraća **konsolidovan rezultat** + rezime odluka i rizika.

### 3.2. Domain Directors

Za veće domene uvodimo **domain-specific direktore**:

- Preuzimaju koordinaciju unutar domena (više specijalizovanih agenata),
- vode evidenciju o prethodnim intervencijama u tom domenu (kroz ReasoningBank),
- rade prvu rundu kvalitativne provere pre nego što rezultat ode nazad na Global Director‑a.

**Napomena:** Domain Directors se uvode tek kada se pokaže da GlobalDirector sam ne može efikasno da vodi neki kontekst. Ne praviti ih preventivno.


## 4. Model routing — "TinyDancer" princip

### 4.1. Model tier‑ovi

**3 nivoa** modela (apstraktno — stvarni provider može da se menja):

- **Tier 1 — Fast / Cheap**: kratki lookup, trivijalne transformacije, lagani refactoring.
- **Tier 2 — Balanced**: većina planiranja, code review, analiza koda, pisanje manjih funkcija.
- **Tier 3 — Deep / Expensive**: kompleksna arhitektura, security promene, veliki refactor, konsenzus.

### 4.2. Routing pravila

Centralni `model_router` modul bira tier na osnovu: tipa zadatka, procene rizika, veličine inputa, važnosti projekta, potrebe za dugim rezonovanjem.

Globalni i domain Director‑i **nikad ne zovu model direktno**, nego preko router‑a.


## 5. ReasoningBank i "dream cycles" — kako swarm uči

### 5.1. Šta čuvamo

Za svaki značajan task:
- kratak opis zadatka,
- ključne ulazne informacije,
- odluke koje su donete,
- ishod (uspeh, problemi, ispravke),
- lessons learned (1–3 kratke rečenice).

Format: plain markdown/JSON (V1), sa mogućnošću kasnijeg embedding index‑a.

### 5.2. Dream cycles

Cron/batch job pokreće **"dream session"** za svaki veći projekat ili domen:
- uzima logove i ReasoningBank zapise,
- generiše konsolidovane lekcije,
- apdejtuje meta‑policy i guidelines.

Director‑i za naredne zadatke učitavaju relevantne lekcije pre planiranja.


## 6. Governance, trust tiers i consensus sloj

### 6.1. Trust tiers

1. **Tier A — Read‑only / Analyst**: čita, analizira, daje predloge.
2. **Tier B — Suggestor (Draft only)**: predlaže, ali output ide u draft za review.
3. **Tier C — Auto‑apply (low risk)**: primenjuje manje promene na feature branch.
4. **Tier D — High‑impact / Protected**: uvek potreban ljudski potpis.

### 6.2. Consensus i coherence

Za rizične zadatke (Tier C/D):
- **multi‑agent consensus**: dva ili više agenata daju rešenje, arbiter spaja/odabira.
- **coherence check**: meta‑agent proverava da li predlog krši policy‑je, arhitekturu ili prethodne odluke.


## 7. Developer UX — kako se koristi swarm

### 7.1. CLI interfejs

- `swarm plan <task>` – generiši plan i decomposition.
- `swarm implement <task-id>` – pokreni chain plan→implement→test.
- `swarm refactor <scope>` – predloži refaktor.
- `swarm test <scope>` – generiši/proveri testove.

### 7.2. Artefakti

Za svaki task swarm proizvodi:
- **Plan** (ako je ne-trivijalan),
- **Predloge promena** (patch, diff, PR draft),
- **Dokumentaciju** (rezime šta je urađeno i zašto),
- **Rizike i otvorena pitanja**,
- **Log/record** za ReasoningBank.


## 8. Infrastrukturni sloj (MVP — kompletiran)

| Komponenta | Fajl | Status |
|---|---|---|
| WS Server | `server/main_ws.py` | DONE |
| Worker (4 executora) | `remote/worker_ws.py` | DONE |
| Protocol | `swarm/protocol.py` | DONE |
| Controller CLI | `scripts/swarm_controller.py` | DONE |
| Dispatcher | `controller/dispatcher_ws.py` | DONE |
| Testovi (19) | `tests/` | DONE |

Detalji o vezi infrastrukturnog i orkestracionog sloja: `docs/TEAM/BRIDGE.md`.

**Infrastrukturni dug** (rešava se u Fazi 6):
- PING/PONG keepalive
- Task persistence (trenutno in-memory)
- Capability registracija
- Broadcasting/queueing za load-balancing
