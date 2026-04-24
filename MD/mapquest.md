# 18OE — Map Implementation Questions

Everything needed to implement `g_18_oe/map.rb`. Items marked ✓ are known/implemented;
items marked ? require information from the physical map.

Map orientation: `LAYOUT = :pointy`, `AXES = { x: :number, y: :letter }`
Coordinate system: rows A–Z then AA–AH (34 rows); columns 2–88.

---

## Status: map.rb substantially complete structurally (2026-04-22)

`g_18_oe/map.rb` exists and the full game initialises cleanly. Outstanding work is
**revenue values** (all still 0), **pre-printed path edges** for several cities, and
**sea zone encoding** (ferry paths, distances, impassable borders).

### What Is Already Known / Implemented

- Full grid coverage — 651 blue hexes
- All 24 regional home city coordinates
- All 8 national region hex lists: UK, SC, FR, PHS, AH, IT, SP, RU
  (`NATIONAL_REGION_HEXES_COMPLETE = true`)
- All 255 LOCATION_NAMES
- SEA_ZONES: 19 named zones with hex lists complete (ferry paths/borders/distances TBD)
- All custom OE tile codes OE1–OE8, OE12–OE18, OE23–OE44
- All standard track tile quantities
- Constantinople: on-map pre-printed yellow at **AA82**; OE eastern terminus
- **Metropolis hexes**: A56, B41, C74, F87, K26, M28, M50, Q30, R55, Y14, AA82, **AB51**
- Blue hex coverage: 651 hexes
- **Terrain**: UK/Ireland/France/Spain/Portugal/Scandinavia/Alps/Italy/Adriatic/
  Carpathians/Balkans/Caucasus/major river crossings all implemented
- **Station markers**: all 255 named locations have `city=revenue:0` or `town=revenue:0`
- Pre-printed yellows (yellow section): Liverpool J25, Manchester J27, Athinai AE72
- **Partial pre-printed info** (revenue set, path edges stripped — in white section):
  London M28, Marseille X33, Dublin I20, Le Havre O28, Bordeaux U24, Lille N31

---

## ✓ Section 1 — Map Grid Bounds (fully resolved)

```
A:  42-52, 66-74          B:  43-57, 63-81
C:  42-58, 64-66, 72-82   D:  41-57, 67-85
E:  24-28, 42-44, 48-58, 66-86
F:  23-29, 49-55, 69-85   G:  16-20, 24-28, 44-46, 50-56, 64-86
H:  15-21, 25-29, 43-47, 51-55, 63-87
I:  14-20, 26-28, 44-52, 64-86
J:  13-19, 23-29, 45-49, 63-87
K:  22-30, 40-50, 54-86   L:  23-31, 37-87
M:  22-30, 34-86          N:  31-85
O:  24, 28-86             P:  19-87
Q:  20-86                 R:  23-87
S:  24-86                 T:  23-81
U:  6-12, 22-80           V:  5-47, 51-79
W:  6-48, 54-78           X:  5-29, 33-37, 43-49, 55-77
Y:  2-28, 44-50, 56-78    Z:  3-27, 41, 45-51, 61-79
AA: 2-22, 48-54, 62-86    AB: 1-19, 27, 39-41, 51-57, 63-71, 77, 83-85
AC: 6-20, 38-40, 54-58, 64-68, 76-86
AD: 5-17, 39, 55, 65-71, 79-87
AE: 52, 68-72, 80-86      AF: 49-53, 67-69, 81-87
AG: 50-52, 68-70
```

---

## ✓ Section 4 — Red (Off-Board) Hex Coordinates (fully resolved)

19 red hexes. (A40 → blue/Skagerrak; E88 → removed entirely; AH87 → blue/no zone.)

```
A:54 A:56    North Sweden (×2)         B:41 B:83    Bergen, Arkhangelsk
D:25         Scottish Highlands        F:87 G:88    Moskva (×2; G88 = gray through-track)
N:1 N:87     New York, Kharkov         S:88 T:87    Sevastopol (×2; S88 = gray through-track)
Z:1          Lisboa (2 station slots)  AB:87        Levant
AD:1         North Africa & Americas   AF:5 AF:11 AF:25   Casablanca, Melilla, Alger
AG:40 AG:88  Tunis, Alexandria & Suez
```

---

## Section 2 — City and Town Types

**Status**: All 255+ named locations have correct geometry. Revenue all `0`. Open question
for each city: actual starting revenue and label letter (if any unconfirmed).

| Coord | City | Type | Status | Notes |
|---|---|---|---|---|
| K46 | Hamburg | city | ✓ | revenue 0; label=Y |
| N49 | Leipzig | city | ✓ | revenue 0; label unknown |
| M50 | Berlin | city | ✓ | revenue 0; label=B |
| L53 | Szczecin | city | ✓ | revenue 0 |
| I50 | Copenhagen | city | ✓ | revenue 0; label=Y; water upgrade cost |
| F49 | Göteborg | city | ✓ | revenue 0; label unknown |
| D57 | Stockholm | city | ✓ | revenue 0; water upgrade cost |
| C48 | Oslo | city | ✓ | revenue 0 |
| R55 | Vienna | city | ✓ | revenue 0; label=A |
| S60 | Budapest | city | ✓ | revenue 0; label=Y |
| V41 | Milan | city | ✓ | revenue 0; label=Y |
| V47 | Venezia | ? | ? | coded `town=revenue:0`; verify city vs town |
| Z47 | Roma | city | ✓ | revenue 0; label=Y |
| Z27 | Barcelona | city | ✓ | revenue 0; label=Y |
| Y14 | Madrid | city | ✓ | revenue 0; label=A; mountain upgrade cost |
| AD17 | Cartagena | city | ✓ | revenue 0 |
| Z1 | Lisboa | offboard+2 cities | ? | revenues by phase needed |
| C74 | Sankt-Peterburg | city | ✓ | revenue 0; label=S |
| O80 | Kiev | city | ✓ | revenue 0; label=Y |
| J73 | Minsk | city | ✓ | revenue 0; label unknown |
| M62 | Warszawa | city | ✓ | revenue 0; label=Y |
| AB51 | Napoli | city | ✓ | revenue 0; label=N |
| AA82 | Constantinople | 2-slot city | ~ | revenue 20/slot; path edges missing |

**Remaining work**: Starting revenues for all named cities. Confirm Venezia V47 type.

---

## Section 3 — Pre-printed Tiles

**Status**:

| Hex | City | Section | Code |
|---|---|---|---|
| J25 | Liverpool | ✓ yellow | `city=revenue:30;label=Y;path=a:2,b:_0;path=a:_0,b:4` |
| J27 | Manchester | ✓ yellow | `city=revenue:20;upgrade=cost:30,terrain:mountain;path=a:1,b:_0;path=a:_0,b:4` |
| AE72 | Athinai | ✓ yellow | `city=revenue:20;path=a:1,b:_0;path=a:5,b:_0` |
| M28 | London | ~ white | `city=revenue:30;label=L;upgrade=cost:30,terrain:water` — both edges missing |
| AA82 | Constantinople | ~ white | `city=revenue:20;city=revenue:20;upgrade=cost:45,terrain:water;label=C` — both edges |

| N31 | Lille | ~ white | `city=revenue:20;label=Y;border=edge:2,type:impassable` — both edges |
| I20 | Dublin | ~ white | `city=revenue:10` — both edges |
| O28 | Le Havre | ~ white | `city=revenue:10` — both edges |
| X33 | Marseille | ~ white | `city=revenue:20;label=Y` — both edges |
| U24 | Bordeaux | ~ white | `city=revenue:10` — both edges |

? **3.1** Confirm path edges for all partial pre-printed hexes above. Once both edges
known, move hex from `white:` section to `yellow:` section in map.rb.

? **3.2** List all hexes with pre-printed green tiles (coordinate, revenue, edges, label).
? **3.3** List all hexes with pre-printed gray tiles.
? **3.4** Are there any pre-printed brown tiles?

---

## Section 5 — Terrain Costs

**Status**: Substantially complete across all regions.

**Implemented (beyond UK/FR/SP/SC/Alps/IT/Adria):**

- **Carpathians** (rows P–T, cols 55–75):
  £30: R51, Q70, O50, O68, P57 |
  £45: Q60, Q62, Q64, Q68, R61, R69, N45, O62, P55, T67, T71, T73 |
  £60: O54, R71, S52, S54, T49, T51

- **Balkans** (rows X–AG, cols 55–80):
  £30: X65, Z63, Z69, Z75, AA68, AB53, AC66, AD65, AF69, AG50 |
  £45: X57, X61, X63, X67, Y62, Y68, Z61, Z65, Z71, AA64, AA72, AB67, AC54 |
  £60: X67, Z67, AA66, AA86, AB65

- **Caucasus** (rows AA–AF, cols 80–88):
  £45: AD81, AD83, AE80, AF83 |
  £60: AA86, AB85, AE82, AE84

- **River crossings**:
  £5: E78 |
  £30: N39, P41, K64, K66, L69, L71, L75, L77, M74, M76, M78, M80, N69–N79 |
  £45: K44, N81, O82, AE52 |
  £60: M34, T23, AB77, AC76, AD71, AG70

? **5.1** Verify against physical map: Caucasus at AA86/AD81–AE84; river routing accuracy;
combined terrain hexes (mountain + water at same hex)?

---

## Section 6 — Sea Zones (Blue Hexes)

**Status**: SEA_ZONES defined with 19 named zones and hex lists complete. No ferry paths,
impassable borders, or distance numbers encoded.

✓ **All 19 zone hex lists implemented**: Celtic Sea, North Atlantic Ocean, North Atlantic
Silver Coast, Bay of Biscay, English Channel, North Sea, Skagerrak (incl. A40), German
Bight, Gulf of Finland, Baltic Sea, Strait of Gibraltar, Balearic Sea, Sea of Sardinia,
Tyrrhenian Sea, Adriatic Sea, Aegean Sea, Levantine Sea, Black Sea, Karkinitsky Bay.

? **6.10** Ferry paths — start hex+edge, end hex+edge, distance number
? **6.11** Impassable borders between sea zones — which edges on which blue hexes?
? **6.12** Sea zone distance numbers for cost calculation

---

## ✓ Section 7 — National Zone Boundaries (COMPLETE)

All 8 zones defined in `game.rb`. `NATIONAL_REGION_HEXES_COMPLETE = true`.
`CITY_NATIONAL_ZONE` overrides: Q38 → FR, O52 → PHS.
`MINOR_EXCLUDED_HOME_CITIES` defined.

⚠️ Two stale entries:
- `NATIONAL_REGION_HEXES['SC']` still contains `A40` (now blue) — remove
- `NATIONAL_REGION_HEXES['RU']` still contains `E88` (removed) — remove

---

## Section 8 — Ports and Ferry Routes

? **8.1** All port city hexes: coordinate, type (public light-blue anchor / private red anchor)
? **8.2** All ferry route paths: start hex+edge, end hex+edge, distance number
? **8.3** North Sea port authority positions (8); Mediterranean port authority positions (8)
? **8.4** White Cliffs Ferry token slot near Lille (N31) — position and encoding

---

## Section 10 — Missing Custom Tile Codes

Double-town tiles commented out — orientations unknown.

? OE9 = edges ? and ? ; OE10 = edges ? and ? ; OE11 = edges ? and ?  (green, qty 3/3/3)
? OE20 = edges ? and ? ; OE21 = edges ? and ? ; OE22 = edges ? and ?  (brown, qty 3/2/6)
? OE19: identify tile type (gap between OE18 green and OE20 brown)
? Do OE9–11 upgrade directly to OE20–22?

---

## Section 11 — Patronage Tiles

? **11.1** Which cities receive patronage tiles? Fixed list or any city?
? **11.2** Hex icons in map.rb or pure game logic?

---

## Section 12 — Off-Board Revenue Values and Path Edges

All best-guess — verify against physical map.

| Hex | Name | Revenues (y/g/b/gray) | Path edges | Notes |
|---|---|---|---|---|
| A54 | ~~North Sweden~~ | — | 1→4 | Gray through-track hex |
| A56 | North Sweden | 30/50/80/100 | 0, 1, 4, 5 | |
| B41 | Bergen | 30/60/80/120 | 1, 3, 4 | |
| B83 | Arkhangelsk | 30/50/60/60 | none | confirm isolated or needs edge |
| D25 | Scottish Highlands | 20/40/50/50 | 0, 5 | |
| F87 | Moskva | 30/50/80/100 | 0, 1, 2, 5 | |
| G88 | ~~Moskva~~ | — | 0→2 | Gray through-track hex |
| N1 | New York | —/60/100/160 | 5 | no yellow phase |
| N87 | Kharkov | 30/40/60/80 | 0, 1, 2 | |
| S88 | ~~Sevastopol~~ | — | 0→1 | Gray through-track hex |
| T87 | Sevastopol | 30/40/60/80 | 1 | |
| Z1 | Lisboa (2 slots) | 30/40/60/80 | 3, 4 | `city=revenue:0 ×2` also set |
| AB87 | Levant | 30/50/80/120 | 1, 2 | |
| AD1 | North Africa & Americas | —/40/80/120 | 4 | no yellow phase |
| AF5 | Casablanca | 30/40/60/80 | 3 | |
| AF11 | Melilla | 30/40/40/40 | 4 | |
| AF25 | Alger | 30/40/60/100 | 2, 3 | |
| AG40 | Tunis | 30/40/50/80 | 3, 4 | |
| AG88 | Alexandria & Suez | —/50/80/120 | 1 | no yellow phase |

---

## Outstanding Bugs to Fix

| Bug | Location | Fix |
|---|---|---|
| Constantinople AA82 no path edges | `map.rb white:` section | Add edges, move to `yellow:` |
| London M28 no path edges | `map.rb white:` section | Add edges, move to `yellow:` |
| SC zone contains A40 | `game.rb NATIONAL_REGION_HEXES` | Remove A40 |
| RU zone contains E88 | `game.rb NATIONAL_REGION_HEXES` | Remove E88 |

---

## Open Issues Summary

| Priority | Item | Needed |
|---|---|---|
| **High** | §2 Revenue values | Starting revenues for all named cities |
| **High** | §3 Pre-printed edges | Edges for M28, AA82, N31, I20, O28, X33, U24 |
| **High** | §12 Verify off-board | Confirm all 19 red hex revenues and edges vs physical map |
| **High** | Bugs | Remove A40/E88 from national zones |
| **Medium** | §6 Sea zones | Ferry paths, impassable borders, distance numbers |
| **Medium** | §8 Ports/ferries | Port markers, ferry routes, distances |
| **Medium** | §5 Verify terrain | Caucasus; river routing accuracy |
| **Low** | §2 Venezia V47 | Confirm town vs city |
| **Low** | §10 Tile orientations | OE9–11, OE20–22 edge pairs; OE19 type |
| **Low** | §11 Patronage | Fixed list or game logic only |

---

_Created: 2026-04-07 | Updated: 2026-04-22 (original mapquest.txt)
Enhanced 2026-04-23: converted to .md; added bugs table, pre-printed tile status table,
national zone stale-entry warnings._
