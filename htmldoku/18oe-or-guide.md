# 18OE — Operating Rounds

OR reference for experienced 18xx players. Covers step sequence, track rights, tile laying, trains, revenue, cross-water, and the Orient Express. Rules: `18OE_Rulebook_v_1.0.txt`.

---

## OR Step Sequence §8

Companies operate in order: **minors and regionals first** (home-token placement order), then **majors and nationals** by share price descending.

| Step | Minor | Regional | Major | National |
|------|-------|----------|-------|----------|
| 1 Lay Track | ✓ (3 pts) | ✓ (3 pts) | ✓ (6 pts) | ✓ (9 pts, no terrain cost) |
| 2 Place Token | ✓ | ✓ | ✓ | — (skipped) |
| 3 Run Trains | ✓ | ✓ | ✓ | ✓ |
| 4 Pay Dividend | Half-pay only | Any | Any | Full-pay only |
| 5 Transfer Tokens | — | — | ✓ (between own majors) | — |
| 6 Buy Trains | ✓ | ✓ | ✓ | ✓ |
| 7 Buy/Sell Shares | — | — | ✓ | ✓ |

---

## Track Rights Zones §3 + §12

Every regional and major belongs to exactly one zone. The zone determines:
- Where it may place tokens (home zone only for regionals; anywhere for majors)
- The **zone fee** paid from treasury at par time (not a cash purchase)
- Any terrain discount on track construction in the zone

| Zone | Countries | Zone fee | Terrain discount | Cap |
|------|-----------|----------|------------------|-----|
| UK | United Kingdom | £40 | — | 4* |
| PHS | Prussia/Holland/Switzerland | £40 | — | 4* |
| FR | France/Belgium | £20 | — | 4* |
| AH | Austria-Hungary | £20 | — | — |
| IT | Italy | £10 | 20% on IT terrain | — |
| SP | Spain/Portugal | £10 | 20% on SP terrain | — |
| RU | Russia | £10 | 20% on RU terrain | — |
| SC | Scandinavia | £10 | 20% on SC terrain | — |

*UK/PHS/FR combined cap: max 4 regionals/majors may hold chits across these three zones total.

**Track rights chit** — each minor receives one chit for its home zone at float time; the chit stays with the minor (or transfers to a major on merger). No chit = cannot place tokens or use terrain discount in that zone. §12A.

---

## Tile Laying §8b

**Tile points** — spent to lay or upgrade tiles.

| Company type | Points per OR |
|--------------|---------------|
| Minor / Regional | 3 |
| Major | 6 |
| National | 9 |

**Point costs:**
- Yellow (new) city: 2 pts · Yellow town: 1 pt · Green/Brown/Gray upgrade: 2 pts · Metropolis (London, Paris, Berlin, Madrid, Sankt-Peterburg, Constantinople): 3 pts

**First-OR exception** (Phase 2 only) — if a newly-floated company cannot connect its home token to any city/town by land or ferry without a sea crossing, it may lay one non-city green tile consuming all remaining tile points (requires ≥1 pt). *(§11.1.9, not yet implemented)*

**Custom tile codes** (18OE-specific):
- OE1–OE3: yellow double-town · OE4–OE8: yellow city
- OE12–OE18: green city · OE23–OE33: brown city · OE34–OE44: gray city

**TILE_UPGRADES_MUST_USE_MAX_EXITS** — when upgrading a city tile, all available exits on the upgraded tile must be used. You cannot leave exits unconnected.

---

## Token Placement §8c

- One token per OR per company; placed during the Place Token step
- **Regionals and minors** — may only token in their home zone
- **Majors** — may token anywhere; zone cost paid from treasury (£10–£40 depending on zone)
- **Nationals** — skip the token step entirely (virtual tokens in all home-zone cities)
- Token slots are limited; standard city-slot rules apply

---

## Trains §7 + §8g

| Level | Express type | Local type | Qty | Face value | Rusts at |
|-------|-------------|------------|-----|------------|----------|
| 2 | 2+2 | — | 30 | £100 | Phase 4 |
| 3 | 3+3 | 3 | 20 | £225 / £200 | Phase 6 |
| 4 | 4+4 | 4 | 10 | £350 / £300 | Phase 8 |
| 5 | 5+5 | 5 | 8 | £475 / £400 | — |
| 6 | 6+6 | 6 | 6 | £600 / £525 | — |
| 7 | 7+7 | 4D | 14 | £750 / £850 | — |
| 8 | 8+8 | 5D | 8 | £900 / £1,000 | — |

Level 8 trains only available after the 4th Level 7 purchase (§11.6).

**D-trains** (4D, 5D) — count cities twice (each city counts at double revenue).

**Train limits by phase:**

| Phase | Minor / Regional | Major | National |
|-------|------------------|-------|----------|
| 1–3 | 2 | 4 | — |
| 4 | 1 | 3 | 4 |
| 5–6 | — (must merge) | 2 | 3 |
| 7–8 | — | 3 | 4 |

**Reserved 2+2 obligation** (§8g) — each regional/major/national must buy a reserved 2+2 from the depot as its very first train purchase (£100). Obligation waived if Phase 4 is reached before the company's first OR. A reserved 2+2 is not the same as a standard train buy; it is gated separately and cannot be deferred if the company has no train.

**Inter-company purchases** — only after Phase 4; minors from minors, regionals from regionals, majors from majors.

---

## Dividends §6d

| Company | Half-pay | Withhold | Full-pay |
|---------|----------|----------|----------|
| Minor | ✓ only | — | — |
| Regional | ✓ | ✓ | ✓ |
| Major | ✓ | ✓ | ✓ |
| National | — | — | ✓ only |

- **Half-pay** — half to shareholders (rounded down to share); half to treasury. No price movement.
- **Withhold** — all to treasury. Price moves LEFT.
- **Full-pay** — all to shareholders. Price moves RIGHT if ≥ share price; else no move.
- **Nationals always full-pay** — all revenue distributed; nothing retained in treasury. Price moves normally.

---

## Cross-Water Routing §8d *(beta — costs not yet implemented)*

The map has two types of water crossings. Both increase effective distance for city-limit purposes.

### Ferry routes

| Route | Connects |
|-------|----------|
| White Cliffs | Lille (N31) ↔ London (M28) |
| Irish Sea | Dublin (I20) ↔ various |
| Adriatic | Ancona/Brindisi area |
| Aegean | Constantinople (AA82) approaches |

Ferry distance counts against a train's city limit. Cost per crossing:
- **Track**: +£5 per ferry distance unit
- **Token**: +£20 per ferry distance unit

### Sea zones

19 named zones (North Sea, Baltic, Western Med, Adriatic, Aegean, Black Sea, and more). Sea crossings cost more than ferry crossings.

- **Track**: +£10 per sea zone crossed
- **Token**: +£40 per sea zone crossed

**Public vs private ports** — a port marked public may be used by any RR. A private port (SHTC or Central Circle private ability) may only be used by the owning company.

**Port authority markers** (§8d.4 — beta) — a major may purchase one PA marker for £125 during its OR (at any point before Buy Trains). North Sea PA covers light-blue zones; Mediterranean PA covers sea-green zones. Each PA marker reduces sea-zone count and ferry distance by 2 for the owning company.

---

## Orient Express §8e *(not yet implemented)*

The Orient Express is a special bonus run available to **majors only**.

**Valid OE route** — must include:
1. Constantinople (AA82, eastern terminus)
2. At least one of: Paris · London · Berlin · Madrid · Sankt-Peterburg
3. Some land track connecting them (may include ferry routes)

**First-run bonus** (added to normal route revenue):
| Phase | Bonus |
|-------|-------|
| 2–4 | +£30 |
| 5–6 | +£60 |
| 7–8 | +£100 |

On the first OE run: +3 RIGHT share price movement (in addition to normal dividend movement).

**Train combining for OE** — Level ≤4 trains may combine; combined level = sum; city limit = combined level. Level 5+, 4D, 5D cannot combine.

**Subsequent runs** — no first-run bonus; no extra share movement. Normal revenue only.

**Mandatory** — if the OE route is the best possible route for the company, the president must run it. **Nationals may not run the OE.**

---

## National Revenue §11 *(partially implemented)*

Nationals have virtual tokens in every city and town in their home zone — no physical tokens needed, no blocking. Revenue calculated in two parts:

1. **Linked** — cities/towns reachable from any national home-zone city via connected track, counted at printed face value. D-trains double linked revenue.
2. **Unlinked** — remaining capacity filled at flat rates: **£60 per city** or **£10 per town**.

Best-first fill: highest-revenue cities assigned to trains first.

---

## Consolidation Phase §13

Triggered by the **first Level 5 purchase**. Occurs once, as a special round between the triggering OR set and the next SR.

- All remaining minors and unfloated regionals **must** merge into a major or be abandoned
- A major may offer merger terms; if no offer, the company is abandoned
- Abandoned company: charter + trains → Open Market; cash → bank; tokens removed; track rights chit stays

---

## End Game §15

**Two triggers — whichever comes first:**

| Trigger | When game ends |
|---------|---------------|
| Bank breaks (cash ≤ 0) | End of current OR set |
| First Level 8 train purchased | End of one more complete OR set |

**Level 8 trigger** — when the first 8+8 is bought, £100,000 remainder cash (20 × £5,000 notes) is injected into the bank. This prevents the bank breaking mid-game from the high train prices. One full OR set then completes.

**Scoring** — players sum: personal cash + share value of all holdings (at current share price) + value of privates held.
