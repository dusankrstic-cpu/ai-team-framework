# Direktiva: Prioritet CLI (Faza 5) pre ReasoningBank-a (Faza 4)

**Datum:** 2026-02-25
**Prioritet:** VISOK
**Rok:** ~2026-03-01 (okvirno)
**Status:** ZAVRŠENA

---

## Kontekst

Orkestracioni kostur je kompletiran (Faze 0–3, 110 testova). Sistem ima core apstrakcije, model routing i governance, ali nema korisnickog interfejsa. Bez CLI-ja, ceo orkestracioni sloj postoji samo kao biblioteka — Dusan ga ne moze koristiti u praksi.

Obe naredne faze (4 i 5) su tehicki spremne (zavisnosti ispunjene). Ovo je strateska odluka o redosledu.

## Zahtev

**Faza 5 (CLI i Developer UX) ima prioritet nad Fazom 4 (ReasoningBank).**

Direktor razvoja treba da:
1. Pripremi TODO zadatke za Fazu 5 kao sledeci blok rada za tim.
2. Faza 4 moze da se radi paralelno ako kapacitet dozvoljava, ali ne na ustrb Faze 5.
3. Kljucni deliverable: funkcionalne komande `swarm plan` i `swarm run` koje demonstriraju end-to-end flow.

## Ocekivani ishod

- `swarm plan "opis zadatka"` — ispisuje plan i subtaskove (human-readable + `--json`).
- `swarm run "opis zadatka"` — izvrsava ceo flow kroz GlobalDirector i vraca rezultat.
- `swarm status` — prikazuje registrovane agente i stanje sistema.
- Smoke testovi za sve CLI komande.
- Dokumentacija integracije sa Claude Code (per TODO.md 5.2).

## Napomene

- Ova direktiva ne menja scope Faze 5 kako je definisan u TODO.md — samo utvrdjuje prioritet.
- Faza 4 nije odlozena na neodredjeno — okvirni rok je ~2026-03-05, odmah nakon CLI-ja.
- Ako DD proceni da neki deo Faze 4 (npr. `log_entry()`) treba ugraditi u Director tokom Faze 5, to je tehnicka odluka i prepustam mu je.
