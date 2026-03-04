# BRIDGE.md — Veza infrastrukturnog i orkestracionog sloja

Ovaj dokument opisuje kako **novi orkestracioni sloj** (`core/`, `contexts/`, `reasoning/`, `cli/`, `config/`) koristi **postojeći infrastrukturni sloj** (`server/`, `remote/`, `swarm/`, `controller/`).

---

## 1. Postojeći infrastrukturni sloj

Infrastrukturni sloj je MVP kompletiran i testiran (19 testova). Obezbeđuje transport i izvršavanje zadataka na remote mašinama.

| Modul | Odgovornost | Javni interfejs |
|-------|-------------|-----------------|
| `server/main_ws.py` | WS server, registar agenata, TASK/RESULT routing | `send_task(agent_id, payload, timeout_s)`, `list_agents()`, `main_async(host, port)` |
| `remote/worker_ws.py` | Worker na VM-u, kind-based executori (shell.run, python.run, llm.call, generic) | `dispatch_task(payload)`, `run_worker(agent_id, ws_url)` |
| `swarm/protocol.py` | Protokol definicije | `SwarmMessage`, `TaskPayload`, `ResultPayload` dataclass-ovi |
| `controller/dispatcher_ws.py` | Programski dispatcher za slanje taskova | `dispatch_task(ws_url, agent_id, instructions, workdir, wait_for_result, timeout_s)` |
| `scripts/swarm_controller.py` | CLI za slanje kind-specific taskova | Shell entrypoint: `--kind`, `--agent-id`, `--cmd`/`--code`/`--prompt` |

### Tipovi poruka (SwarmMessage)

| Tip | Smer | Opis |
|-----|------|------|
| `HELLO` | worker → server | Registracija agenta |
| `TASK` | controller → server → worker | Zadatak za izvršavanje |
| `RESULT` | worker → server → controller | Rezultat izvršavanja |
| `STATUS` | server → worker/controller | Stanje sistema |
| `ERROR` | bilo koji → bilo koji | Greška |

### Kind executori (worker)

| Kind | Input | Output |
|------|-------|--------|
| `shell.run` | `--cmd`, `--workdir`, `--timeout` | stdout, stderr, exit_code |
| `python.run` | `--code` | `_result` ili `result` varijabla, traceback na grešku |
| `llm.call` | `--prompt`, `--system`, `--workdir` | Claude CLI stdout/stderr/exit_code |
| `generic` | slobodan JSON | Echo (vraća isti JSON) |

---

## 2. Novi orkestracioni sloj

Orkestracioni sloj dodaje **inteligentnu orkestraciju** iznad transporta: razumevanje zadataka, dekompoziciju, routing na specijalizovane kontekste i učenje iz iskustva.

| Paket | Odgovornost | Ključne klase |
|-------|-------------|---------------|
| `core/` | Zajedničke apstrakcije | `SwarmTask`, `TaskResult`, `Agent`, `BoundedContext`, `GlobalDirector` |
| `contexts/` | Specijalizovani domeni | `PlanningContext`, `CodeUnderstandingContext`, `FeatureImplementationContext` |
| `reasoning/` | Pamćenje i učenje | `ReasoningBank`, dream cycle |
| `cli/` | Korisnički interfejs | `swarm plan`, `swarm run`, `swarm analyze`, `swarm status` |
| `config/` | Konfiguracija | Model tier-ovi, governance pravila |

---

## 3. Tačke povezivanja

Orkestracioni sloj se vezuje za infrastrukturni na **dva mesta**:

### 3.1. `controller/dispatcher_ws.py` — remote izvršavanje

`GlobalDirector` koristi `dispatcher_ws.dispatch_task()` kada treba da izvrši zadatak na remote VM-u (npr. shell komandu ili Python kod).

```python
# U core/director.py (Faza 1):
from controller.dispatcher_ws import dispatch_task

async def execute_remote(self, agent_id: str, instructions: str, workdir: str):
    result = await dispatch_task(
        ws_url=self.ws_url,
        agent_id=agent_id,
        instructions=instructions,
        workdir=workdir,
        wait_for_result=True,
        timeout_s=120
    )
    return result
```

### 3.2. `swarm/protocol.py` — zajedničke definicije

Orkestracioni sloj koristi `SwarmMessage`, `TaskPayload` i `ResultPayload` za komunikaciju sa infrastrukturnim slojem. Ove klase su **deljeni interfejs** između dva sloja.

```python
# U core/task.py (Faza 1):
from swarm.protocol import TaskPayload, ResultPayload

# SwarmTask se konvertuje u TaskPayload za remote izvršavanje
# ResultPayload se parsira nazad u TaskResult
```

---

## 4. Tok podataka

### 4.1. Lokalni tok (bez WS-a)

Zadaci koji ne zahtevaju remote izvršavanje (analiza koda, planiranje) rade potpuno lokalno:

```
CLI / Korisnik
    │
    ▼
GlobalDirector.handle(task)
    │
    ├─► PlanningContext.execute(task)
    │       └─► PlannerAgent.handle_task(task)
    │               └─► LLM poziv (lokalni)
    │               └─► return TaskResult (lista subtaskova)
    │
    ├─► CodeUnderstandingContext.execute(task)
    │       └─► CodeAnalyzerAgent.handle_task(task)
    │               └─► Čitanje fajlova + LLM analiza
    │               └─► return TaskResult (analiza koda)
    │
    └─► return konsolidovani TaskResult
```

### 4.2. Remote tok (kroz WS infrastrukturu)

Zadaci koji zahtevaju izvršavanje na VM-u idu kroz WS infrastrukturu:

```
GlobalDirector
    │
    ▼
FeatureImplementationContext.execute(task)
    │
    ▼
ImplementerAgent.handle_task(task)
    │
    ▼ [konverzija SwarmTask → TaskPayload]
    │
dispatcher_ws.dispatch_task(ws_url, agent_id, instructions, workdir)
    │
    ▼ [WebSocket]
    │
server/main_ws.py ─── routing ──► remote/worker_ws.py
                                        │
                                        ▼
                                   dispatch_task(payload)
                                        │
                                        ├─► shell.run executor
                                        ├─► python.run executor
                                        └─► llm.call executor
                                        │
                                        ▼
                                   RESULT ──► server ──► dispatcher ──► Director
```

---

## 5. Lokalno vs. remote izvršavanje

| Context | Izvršavanje | Razlog |
|---------|-------------|--------|
| `contexts/planning/` | **Lokalno** | Planiranje je LLM-only, ne zahteva shell pristup |
| `contexts/code_understanding/` | **Lokalno** | Čita lokalne fajlove, analizira strukturu |
| `contexts/feature_implementation/` | **Može remote** | Generisanje koda je lokalno (LLM), ali testiranje/izvršavanje može ići na VM |

### Odluka o local vs. remote

`GlobalDirector` odlučuje na osnovu:
1. **Tipa zadatka** — `PLAN` i `ANALYZE` su uvek lokalni
2. **Potrebe za shell pristupom** — ako treba pokrenuti komandu, ide remote
3. **Dostupnosti workera** — `server.main_ws.list_agents()` vraća listu aktivnih agenata

---

## 6. Error putanje

### 6.1. Remote greška (worker → Director)

```
Worker executor fails
    │
    ▼
worker_ws.build_result_message(status="failed", details={...})
    │
    ▼ [RESULT poruka sa status="failed"]
    │
server/main_ws.py ──► forwarding ──► dispatcher_ws
    │
    ▼
dispatcher_ws.dispatch_task() vraća result sa status="failed"
    │
    ▼
ImplementerAgent prima ResultPayload(status="failed")
    │
    ▼
FeatureImplementationContext vraća TaskResult(status="failed")
    │
    ▼
GlobalDirector loguje grešku + odlučuje: retry / escalate / fail
```

### 6.2. Konekcijski problemi

```
dispatcher_ws.dispatch_task() ──► WebSocket timeout/connection error
    │
    ▼
asyncio.TimeoutError ili ConnectionRefusedError
    │
    ▼
ImplementerAgent hvata exception ──► TaskResult(status="failed", log="WS connection error")
    │
    ▼
GlobalDirector ──► retry sa drugim agent-om / eskalacija
```

### 6.3. Nepostojeći agent

```
dispatcher_ws šalje TASK za agent koji nije connected
    │
    ▼
server/main_ws.py šalje ERROR poruku: "Agent not found"
    │
    ▼
dispatcher_ws vraća error result
    │
    ▼
Director ──► pokušava drugi agent ili čeka reconnect
```

---

## 7. Arhitektura — ASCII dijagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ORKESTRACIONI SLOJ (novo)                        │
│                                                                     │
│  ┌──────────┐                                                       │
│  │ cli/     │    swarm plan / run / analyze / status                │
│  └────┬─────┘                                                       │
│       │                                                             │
│       ▼                                                             │
│  ┌──────────────────────────────────────────────────────┐           │
│  │              core/director.py                         │           │
│  │              GlobalDirector                           │           │
│  │  ┌───────────────┬───────────────┬──────────────┐    │           │
│  │  │ task analysis  │ decomposition │ aggregation  │    │           │
│  │  └───────────────┴───────────────┴──────────────┘    │           │
│  └──────┬──────────────────┬──────────────────┬─────────┘           │
│         │                  │                  │                      │
│         ▼                  ▼                  ▼                      │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐            │
│  │  contexts/  │  │  contexts/   │  │   contexts/     │            │
│  │  planning/  │  │  code_under- │  │   feature_      │            │
│  │             │  │  standing/   │  │   implementation/│            │
│  │ PlannerAgent│  │ CodeAnalyzer │  │ ImplementerAgent│            │
│  │   (lokalno) │  │   (lokalno)  │  │ (lokalno+remote)│            │
│  └─────────────┘  └──────────────┘  └────────┬────────┘            │
│                                               │                     │
│  ┌───────────────────┐    ┌─────────────┐     │                     │
│  │ reasoning/        │    │ config/     │     │                     │
│  │ ReasoningBank     │    │ models.py   │     │                     │
│  │ dream cycles      │    │ governance  │     │                     │
│  └───────────────────┘    └─────────────┘     │                     │
│                                               │                     │
├───────────────────────────────────────────────┼─────────────────────┤
│              TAČKE POVEZIVANJA                │                     │
│  ┌────────────────────────────┐               │                     │
│  │ swarm/protocol.py          │◄──────────────┤ (zajedničke         │
│  │ SwarmMessage, TaskPayload  │               │  definicije)        │
│  └────────────────────────────┘               │                     │
│  ┌────────────────────────────┐               │                     │
│  │ controller/dispatcher_ws.py│◄──────────────┘ (remote dispatch)   │
│  │ dispatch_task()            │                                     │
│  └─────────────┬──────────────┘                                     │
├────────────────┼────────────────────────────────────────────────────┤
│                │     INFRASTRUKTURNI SLOJ (postojeći)               │
│                ▼                                                     │
│  ┌─────────────────────────┐                                        │
│  │ server/main_ws.py       │  WS Server                             │
│  │ Agent registar          │  TASK routing                          │
│  │ RESULT forwarding       │  Future-based correlation              │
│  └─────────────┬───────────┘                                        │
│                │ WebSocket                                           │
│                ▼                                                     │
│  ┌─────────────────────────┐                                        │
│  │ remote/worker_ws.py     │  Worker (VM: 192.168.1.213)            │
│  │ ┌─────────┬──────────┐  │                                        │
│  │ │shell.run│python.run│  │                                        │
│  │ ├─────────┼──────────┤  │                                        │
│  │ │llm.call │ generic  │  │                                        │
│  │ └─────────┴──────────┘  │                                        │
│  └─────────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. Sažetak principa

1. **Orkestracioni sloj ne menja infrastrukturni.** Koristi ga kao crnu kutiju kroz javne interfejse.
2. **Dva mesta kontakta:** `dispatcher_ws.dispatch_task()` za remote izvršavanje i `swarm.protocol` za zajedničke tipove.
3. **Lokalno kad može, remote kad mora.** Planning i code understanding su lokalni; implementacija može da ide remote.
4. **Greške se propagiraju nagore.** Worker → server → dispatcher → agent → context → Director.
5. **Infrastrukturni dug se rešava odvojeno.** PING/PONG, persistence, queueing su infrastrukturni taskovi koji ne blokiraju orkestracioni sloj.
