# 18OE — Map Implementation Questions

Everything needed to implement `g_18_oe/map.rb` — the full European base game map.
Items marked ✓ are already known / implemented; items marked ? require information
from the physical map (zoomed images needed).

---

## Coordinate System Note

The 34 map rows use letters A–Z then **AA, AB, AC, AD, AE, AF, AG, AH**.
Earlier versions used BB/DD/FF/GG/HH — those names are wrong.
All coordinates below use the current scheme.

Map orientation: `LAYOUT = :pointy`, `AXES = { x: :number, y: :letter }`

---

## Status: map.rb substantially complete structurally (2026-04-22)

`g_18_oe/map.rb` exists and the full game initialises cleanly. Most geometry is done.
Outstanding work is **revenue values** (all still 0), **pre-printed path edges** for
several cities, and **sea zone encoding** (ferry paths, distances, impassable borders).

### What Is Already Known / Implemented

- Full grid coverage — 651 blue hexes
- All 24 regional home city coordinates
- All 8 national region hex lists: UK, SC, FR, PHS, AH, IT, SP, RU (`NATIONAL_REGION_HEXES_COMPLETE = true`)
- All 255 LOCATION_NAMES entries (A40, E88, AH87 removed)
- SEA_ZONES: 19 named zones with hex lists complete (ferry paths/borders/distances TBD)
- All custom OE tile codes OE1–OE8, OE12–OE18, OE23–OE44
- All standard track tile quantities (TILES in game.rb)
- Constantinople: on-map, pre-printed yellow at **AA82**; OE eastern terminus
- **Metropolis hex list confirmed**: A56, B41, C74, F87, K26, M28, M50, Q30, R55, Y14, AA82, **AB51**
  - ⚠️ Bug: `game.rb#metropolis_hex?` still uses `BB51` — must be corrected to `AB51`
- Six game-rule sea zones via 19 named SEA_ZONES entries
- Blue hex coverage: 651 hexes (17 col-0 hexes removed; A40 and AH87 converted red→blue)
- **Terrain**: UK/Ireland/France/Spain/Portugal/Scandinavia/Alps/Italy/Adriatic/
  Carpathians/Balkans/Caucasus/major river crossings all implemented
- **Station markers**: all 255 named locations have `city=revenue:0` or `town=revenue:0`
- Pre-printed yellows (in yellow section): Liverpool J25 (edges 2,4; rev 30; label=Y),
  Manchester J27 (edges 1,4; rev 20; mountain), Athinai AE72 (edges 1,5; rev 20)
- **Partial pre-printed info** (revenue set, path edges stripped pending confirmation):
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

19 red hex coordinates. (A40 → blue/Skagerrak; E88 → removed entirely; AH87 → blue/no zone.)
Revenue values and path edges implemented in map.rb (best-guess, see §12 for verification status).

```
A:54 A:56           North Sweden (×2)
B:41 B:83           Bergen, Arkhangelsk
D:25                Scottish Highlands
F:87 G:88           Moskva (×2, G88 is gray through-track hex)
N:1 N:87            New York, Kharkov
S:88 T:87           Sevastopol (×2, S88 is gray through-track hex)
Z:1                 Lisboa (2 station slots; RCP home in top slot)
AB:87               Levant
AD:1                North Africa & The Americas
AF:5 AF:11 AF:25    Casablanca, Melilla, Alger
AG:40 AG:88         Tunis, Alexandria & Suez
```

---

## Section 2 — City and Town Types

**Status**: All 255+ named locations have correct geometry from cities.csv. Revenue
values still all placeholder `revenue:0`. Open question for each city: actual starting
revenue and label letter (if any).

| Coord | City | Status | Notes |
|---|---|---|---|
| K46 | Hamburg | ✓ geometry | revenue 0; label=Y |
| N49 | Leipzig | ✓ geometry | revenue 0; label unknown |
| M50 | Berlin | ✓ geometry | revenue 0; label=B |
| L53 | Stettin/Szczecin | ✓ geometry | revenue 0 |
| I50 | Copenhagen | ✓ geometry | revenue 0; label=Y; water upgrade cost |
| F49 | Göteborg | ✓ geometry | revenue 0; label unknown |
| D57 | Stockholm | ✓ geometry | revenue 0; water upgrade cost |
| C48 | Oslo | ✓ geometry | revenue 0 |
| R55 | Wien/Vienna | ✓ geometry | revenue 0; label=A |
| S60 | Budapest | ✓ geometry | revenue 0; label=Y |
| V41 | Milan | ✓ geometry | revenue 0; label=Y |
| V47 | Venezia | ? | coded `town=revenue:0`; verify city vs town |
| Z47 | Roma | ✓ geometry | revenue 0; label=Y |
| Z27 | Barcelona | ✓ geometry | revenue 0; label=Y |
| Y14 | Madrid | ✓ geometry | revenue 0; label=A; mountain upgrade cost |
| AD17 | Cartagena | ✓ geometry | revenue 0 |
| Z1 | Lisboa | ? | offboard+2 cities; revenues by phase needed |
| C74 | Sankt-Peterburg | ✓ geometry | revenue 0; label=S |
| O80 | Kiev | ✓ geometry | revenue 0; label=Y |
| J73 | Minsk | ✓ geometry | revenue 0; label unknown |
| M62 | Warszawa | ✓ geometry | revenue 0; label=Y |
| AB51 | Napoli | ✓ geometry | revenue 0; label=N (old refs used BB51 — wrong) |
| AA82 | Constantinople | ~ | two city slots; revenue 20/slot; path edges missing |

**Remaining work for §2**: Provide starting revenue values for all named cities, and
confirm whether V47 (Venezia) should be city or town.

---

## Section 3 — Pre-printed Tiles (Yellow / Green / Gray)

**Status**:

| Hex | City | Yellow section | Pre-printed code |
|---|---|---|---|
| J25 | Liverpool | ✓ | `city=revenue:30;label=Y;path=a:2,b:_0;path=a:_0,b:4` |
| J27 | Manchester | ✓ | `city=revenue:20;upgrade=cost:30,terrain:mountain;path=a:1,b:_0;path=a:_0,b:4` |
| AE72 | Athinai | ✓ | `city=revenue:20;path=a:1,b:_0;path=a:5,b:_0` |
| M28 | London | ~ white | `city=revenue:30;label=L;upgrade=cost:30,terrain:water` — both edges missing |
| AA82 | Constantinople | ~ white | `city=revenue:20;city=revenue:20;upgrade=cost:45,terrain:water;label=C` — both edges |
| AB51 | Napoli | ~ white | `city=revenue:20;label=N;path=a:1,b:_0` — second edge missing |

**Partial pre-printed info** (in white section — path edges stripped pending confirmation):

| Hex | City | Current code | Missing |
|---|---|---|---|
| N31 | Lille | `city=revenue:20;label=Y;border=edge:2,type:impassable` | both edges |
| I20 | Dublin | `city=revenue:10` | both edges |
| O28 | Le Havre | `city=revenue:10` | both edges |
| X33 | Marseille | `city=revenue:20;label=Y` | both edges |
| U24 | Bordeaux | `city=revenue:10` | both edges |

? **3.1** Confirm path edges for all partial pre-printed hexes above. Once both edges
known, move hex from `white:` section to `yellow:` section in map.rb.

? **3.2** List all hexes with pre-printed green tiles. For each: coordinate, revenue,
track connection edges, label.

? **3.3** List all hexes with pre-printed gray tiles. Same fields.

? **3.4** Are there any hexes with pre-printed brown tiles?

---

## Section 5 — Terrain Costs

**Status**: All terrain substantially complete.

### Implemented (beyond UK/FR/SP/SC/Alps/IT/Adria):

- **Carpathians** (rows P–T, cols 55–75):
  - £30: R51, Q70, O50, O68, P57
  - £45: Q60, Q62, Q64, Q68, R61, R69, N45, O62, P55, T67, T71, T73
  - £60: O54, R71, S52, S54, T49, T51

- **Balkans** (rows X–AG, cols 55–80):
  - £30: X65, Z63, Z69, Z75, AA68, AB53, AC66, AD65, AF69, AG50
  - £45: X57, X61, X63, X67, Y62, Y68, Z61, Z65, Z71, AA64, AA72, AB67, AC54
  - £60: X67, Z67, AA66, AA86, AB65

- **Caucasus** (rows AA–AF, cols 80–88):
  - £45: AD81, AD83, AE80, AF83
  - £60: AA86, AB85, AE82, AE84

- **River crossings**:
  - £5 water: E78
  - £30 water: N39, P41, K64, K66, L69, L71, L75, L77, M74, M76, M78, M80, N69–N79
    (Vistula/Bug/Dnieper), Rhine/Elbe at N39/P41
  - £45 water: K44, N81, O82, AE52
  - £60 water: M34 (Rhine delta), T23, AB77, AC76, AD71, AG70

? **5.1** Verify terrain coverage against physical map:
- Caucasus: is coverage at AA86, AD81–AE84 accurate?
- River crossings: does Rhine/Elbe/Danube/Vistula/Dnieper routing match map?
- Any combined terrain hexes (mountain + water at same hex)?

? **5.2** Are there any hexes with combined terrain (e.g. mountain + water)?

---

## Section 6 — Sea Zones (Blue Hexes)

**Status**: SEA_ZONES defined with 19 named zones and hex lists complete. All blue
hexes are plain `''` tiles — no ferry paths or impassable borders encoded. Distance
numbers not encoded.

✓ **Implemented zones** (hex lists complete): Celtic Sea, North Atlantic Ocean, North
Atlantic Silver Coast, Bay of Biscay, English Channel, North Sea, Skagerrak (incl. A40),
German Bight, Gulf of Finland, Baltic Sea, Strait of Gibraltar, Balearic Sea, Sea of
Sardinia, Tyrrhenian Sea, Adriatic Sea, Aegean Sea, Levantine Sea, Black Sea,
Karkinitsky Bay.

? **6.10** Ferry paths through sea zones — start hex+edge, end hex+edge, distance number
? **6.11** Impassable borders between sea zones — which edges on which blue hexes?
? **6.12** Sea zone distance numbers for cost calculation — confirm per-zone values

---

## ✓ Section 7 — National Zone Boundaries (COMPLETE)

All 8 zone hex lists defined in `game.rb`. `NATIONAL_REGION_HEXES_COMPLETE = true`.
`CITY_NATIONAL_ZONE` overrides: Q38 → FR, O52 → PHS. `MINOR_EXCLUDED_HOME_CITIES` defined.

Note: Belgium hexes in N31–N35 area overlap PHS/FR; resolved by `CITY_NATIONAL_ZONE` override.

⚠️ Two stale entries:
- `NATIONAL_REGION_HEXES['SC']` still contains `A40` (now blue) — remove
- `NATIONAL_REGION_HEXES['RU']` still contains `E88` (removed from map) — remove

---

## Section 8 — Ports and Ferry Routes

? **8.1** List all port city hexes (land hexes adjacent to sea zones with port symbol):
coordinate, port type (public light-blue anchor / private red anchor)

? **8.2** List all ferry route paths through sea zones:
start hex+edge, end hex+edge, distance number

? **8.3** North Sea port authority positions (8 markers) — which hexes?
Mediterranean port authority positions (8 markers) — which hexes?

? **8.4** White Cliffs Ferry token slot near Lille (N31) — confirm position and encoding
in full-game map vs UK-FR map.

---

## Section 9 — Additional Location Names

All currently known names are implemented in map.rb LOCATION_NAMES.

✓ Venezia/Venice: confirmed at V47 (coded as `town=revenue:0` — see §2 for type query).

---

## Section 10 — Missing Custom Tile Codes (OE9–OE11, OE20–OE22)

Double-town tiles commented out in game.rb — orientations unknown.

? **10.1** Path orientations for yellow double-town tiles:
OE9 = edges ? and ? ; OE10 = edges ? and ? ; OE11 = edges ? and ?

? **10.2** Path orientations for brown double-town tiles:
OE20 = edges ? and ? ; OE21 = edges ? and ? ; OE22 = edges ? and ?

? **10.3** Do OE9–OE11 upgrade directly to OE20–OE22 (same orientation)?

---

## Section 11 — Patronage Tiles

? **11.1** Which cities receive patronage tiles? Fixed list or any city?
? **11.2** Are patronage tiles hex icons in map.rb, or pure game logic?

---

## Section 12 — Off-Board Revenue Values and Path Edges

19 red hexes. Revenues and path edges implemented (best-guess — verify against physical map).

| Hex | Name | Revenues (y/g/b/gray) | Path edges | Notes |
|---|---|---|---|---|
| A54 | ~~North Sweden~~ | — | 1→4 | Changed to gray through-track hex |
| A56 | North Sweden | 30/50/80/100 | 0, 1, 4, 5 | |
| B41 | Bergen | 30/60/80/120 | 1, 3, 4 | |
| B83 | Arkhangelsk | 30/50/60/60 | none | no path defined — confirm |
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

? Verify all revenue values and edge numbers against physical map — currently best-guess.
? B83 Arkhangelsk has no path — confirm whether truly isolated or needs an edge.

---

## Outstanding Bugs to Fix

| Bug | Location | Fix |
|---|---|---|
| `BB51` should be `AB51` | `game.rb#metropolis_hex?` | Correct coordinate string |
| `AB51` missing from label check | `game.rb#upgrades_to_correct_label?` | Add `when 'AB51' then to.label.to_s.include?('N')` |
| Constantinople AA82 no path edges | `map.rb white:` section | Add edges, move to `yellow:` section |
| London M28 no path edges | `map.rb white:` section | Add edges, move to `yellow:` section |
| AB51 Napoli `path=a:1,b:_0` | `map.rb white:` section | Edge 1 → sea hex; confirm correct non-sea edge |
| NATIONAL_REGION_HEXES SC contains A40 | `game.rb` | Remove A40 from SC zone list |
| NATIONAL_REGION_HEXES RU contains E88 | `game.rb` | Remove E88 from RU zone list |

---

## Open Issues Summary

| Priority | Item | Needed |
|---|---|---|
| **High** | §2 Revenue values | Starting revenues for all named cities (all placeholder 0) |
| **High** | §3 Pre-printed edges | Both edges for M28, AA82, N31, I20, O28, X33, U24; second edge for AB51 |
| **High** | §12 Verify off-board | Confirm revenue values and path edges vs physical map |
| **High** | Bugs | Fix BB51→AB51; add AB51 case to upgrades_to_correct_label?; remove A40/E88 from national zones |
| **Medium** | §6 Sea zones | Ferry paths, impassable borders, distance numbers |
| **Medium** | §8 Ports/ferries | Port markers, ferry routes, distances |
| **Medium** | §5 Verify terrain | Caucasus; river routing accuracy |
| **Low** | §2.12 Venezia V47 | Confirm town vs city |
| **Low** | §10 Tile orientations | OE9–11, OE20–22 edge pairs |
| **Low** | §11 Patronage | Fixed list or game logic only |

---

_Created: 2026-04-07 | Updated: 2026-04-22 — original mapquest.txt
Enhanced 2026-04-23: converted to .md; added bugs table, status table for §3 pre-printed
tiles, and national zone stale-entry warnings; structured §12 off-board table._
