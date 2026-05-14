# 18OE — Player Guide

Quick reference for experienced 18xx players new to 18OE. Assumes familiarity with 18xx mechanics. Rules references: `18OE_Rulebook_v_1.0.txt`.

---

## What Makes 18OE Different

- **Four company types** — Minors and regionals run in parallel; regionals *convert* to majors; minors *merge into* majors; nationals form by presidential choice or are forced (never automatic)
- **Track rights zones** — regionals and minors can only token inside their home zone; majors can token anywhere but pay the token cost from treasury
- **Incremental capitalisation** — companies receive only the cash from shares sold so far
- **7-row waterfall auction** — privates + minor auction cards sold before a single OR runs
- **Orient Express** — special multi-bonus run linking Constantinople to a western terminus
- **Cross-water routing** — ferry and sea crossings with distance costs (§8d)
- **Nationals** — formed by presidential choice at Phase 4/6/8 trigger, or forced; unique flat-rate revenue; no tokens

---

## Setup

| Players | Starting Cash | Cert Limit | Bank |
|---------|---------------|------------|------|
| 2 | £2,600 | 99 | £54,000 |
| 3 | £1,800 | 48 | £54,000 |
| 4 | £1,350 | 36 | £54,000 |
| 5 | £1,080 | 29 | £54,000 |
| 6 | £900 | 24 | £54,000 |
| 7 | £775 | 20 | £54,000 |

2-player uses a without-concessions variant (starting cash already reflects this).

---

## Company Types

| Type | Shares | Par range | Float | Dividends | Tokens | Zone |
|------|--------|-----------|-------|-----------|--------|------|
| Minor | 1 × 100% | £120 fixed | Via auction card | Half-pay only | 1 | Home zone only |
| Regional | 50%+25%+25% | £60–£90 | Pay 2× par to treasury | Any | 2–3 | Home zone only |
| Major | 20%+8×10% | £75–£120 | Regional *converts* into major | Any | Varies | Anywhere (cost) |
| National | 20%+8×10% | Inherits major | Major converts — choice or forced | Full-pay only | None | Entire zone (virtual) |

**Minors and regionals run in parallel** during the Regional/Minor Phase — they are not a progression. A regional *converts* to a major in a SR (president pays 2× par). A minor *merges into* an existing major (absorbed, not converted). Both relationships are independent.

A major *becomes a national* when its president chooses to convert (at Phase 4/6/8 trigger) — or is forced to (bankruptcy, consolidation). Conversion is never automatic.

**Incremental capitalisation** — treasury receives only the proceeds of shares actually sold. Unsold shares in treasury pay no revenue to the bank; they dilute the dividend per share.

---

## Game Flow

```
Auction Phase
  └── Regional/Minor Phase  (SRs + ORs, 2 ORs per set)
  │     Minors and regionals float and run in parallel
  │     Regionals may convert to majors during any SR (president pays 2× par)
  │     Minors may merge into majors during any SR
  │     Phase ends: 18 regionals floated AND all 12 minors floated
  └── Major Phase  (SRs + ORs, 2 ORs per set)
        Remaining minors/regionals still in play
        First Level 5 purchase → Consolidation Round (once)
        Continue until bank break OR Level 8 purchase
          Bank break → finish current OR set
          Level 8 → one more full OR set (+ £100,000 remainder cash injected)
```

**Train phases 1–8** triggered by highest level train purchased. Phase determines tile colours, train limits, and which events fire.

---

## Auction Phase §4

Items sold in a **7-row waterfall**. Rows open sequentially; each row is cleared before the next opens. Within a row items sell left-to-right. Players buy one item per turn or pass; unpurchased items drop £5 per full pass cycle.

| Row | Items | Face value |
|-----|-------|-----------|
| 1 | Robert Stephenson · Ponts et Chaussées (no abilities) | £20 |
| 2 | Wien Südbahnhof · Barclay, Bevan & Tritton | £40 |
| 3 | Star Harbor · Central Circle · White Cliffs Ferry | £60 |
| 4 | Hochberg Mining · Brandt & Brandau · Swift Metropolitan | £80 |
| 5 | Minor cards A · B · C | £120 par |
| 6 | Minor cards D · E · F · G | £120 par |
| 7 | Minor cards H · J · K · L · M | £120 par |

**Minor auction card** — buying one immediately floats that minor at £120 par. The player places its home token during the Regional/Minor Phase (before its first OR).

**All-pass price reduction** *(§4.3, not yet implemented in digital)* — if all players consecutively pass on the opening row, items pay their printed dividend then all drop £5. Repeats until a purchase is made; items at £0 must be taken.

---

## Privates §10

Privates pay printed revenue at the start of every OR. Held by players; cannot be sold. Relevant to train purchase: owning a private does not count toward the cert limit.

| Sym | Name | Row | Rev | Ability |
|-----|------|-----|-----|---------|
| RSC | Robert Stephenson | 1 | £5 | None |
| PeC | Ponts et Chaussées | 1 | £5 | None |
| WS | Wien Südbahnhof | 2 | £10 | Free token placement anywhere (sea costs still apply) |
| BBBT | Barclay, Bevan & Tritton | 2 | £10 | Choose one: reset par · custodianship share · block DOWN |
| SHTC | Star Harbor | 3 | £15 | Extra free token slot at any port city |
| CCTC | Central Circle | 3 | £15 | Extra free token slot at non-port city; revenue £10/£20/£40/£60 |
| WCF | White Cliffs Ferry | 3 | £15 | Phase 5: place one token on White Cliffs Ferry slot at Lille |
| HMG | Hochberg Mining | 4 | £20 | Mining token on ≥£45 terrain hex; only owner's RRs use that track |
| BB | Brandt & Brandau | 4 | £20 | 4 free tile lays total (max 2/OR); no terrain cost |
| SML | Swift Metropolitan | 4 | £20 | From Phase 4: one controlled RR keeps a preserved 2+2 outside limit |

---

## Minor Abilities §9

Each minor has a unique permanent ability. All transfer to the absorbing major on merger (§10.4 — beta scope in digital).

| Sym | Name | Ability |
|-----|------|---------|
| A | Silver Banner Line | Bank pays the major's current share price into the major's treasury when the minor merges |
| B | Orange Scroll | All track upgrades cost 1 tile point (including town tiles) |
| C | Golden Bell | President chooses operating position (first or last) at each OR start |
| D | Green Junction | Place bonus token on any unreachable non-metropolis land city |
| E | Blue Coast | 33% water/coast terrain discount; one extra tile lay per OR |
| F | White Peak | 33% mountain terrain discount; one extra tile lay per OR |
| G | Indigo Foundry | +2 tile points every OR |
| H | Great Western Steamship | Reduces sea-zone city-limit count by 1 (Ph1–6) or 2 (Ph7–8) |
| J | Grey Loco Works | 10% discount on all train purchases (including Pullman cars) |
| K | Vermilion Seal | Mail contract: bank pays treasury £20/£40/£40/£50/£50/£60/£60 (Ph2–8) at OR start |
| L | Krasnaya Strela | +1+1 marker assigned to one train each OR (train runs one further city each end) |
| M | CIWL | Holds 10 Pullman cars; receives one free Pullman at Phase 4 start |

---

## Stock Round §6

- **Order**: sell then buy (standard 18xx sell-buy)
- **One buy per turn** — one share or par action only; unlimited sells before the buy
- **Minors and regionals** — exempt from share price movement (price fixed until conversion)
- **Holding limit** — buying a share from the bank pool that would push your holding above 60% of that company costs 2× share price (§10.2); you may still buy it, just at double cost
- **Multiple sells** — you may sell shares of different companies in one turn (`MUST_SELL_IN_BLOCKS = false`); no need to sell all shares of one company at once
- **Reserved secondary shares** — in the Initial SR only, one 25% share per regional may be reserved by a player; no one else may buy it until the second SR (§6.3) *(not yet implemented)*

**Par values:**
- Regional: £60 / £65 / £70 / £75 / £80 / £90 (blue band)
- Major: £75 / £80 / £90 / £100 / £110 / £120 (red band — only when converting from regional)

**Incremental float** — a regional floats when cash paid in by shareholders ≥ 2× par. Cash in treasury = total shares sold × par.

---

## Share Price Movement §6b

| Trigger | Movement |
|---------|----------|
| Dividend ≥ share price | RIGHT (one step) |
| Dividend > 0 but < share price | No movement |
| Zero dividend | LEFT (one step) |
| All shares in player hands at SR end | UP (one step) |
| Each share sold in SR | DOWN (one step) |
| First Orient Express run | +3 RIGHT (in addition to normal dividend move) |

- **£550** — maximum price; no movement possible
- **Minors and regionals** — no share price movement until converted to major
- **Nationals** — move normally

---

## Regional → Major Conversion §8.5

Conversion is triggered during a SR by **any player holding ≥50%** of the regional (the president, or a player holding both 25% certs). It is its own action — you cannot convert and buy/sell in the same turn.

**What happens:**
1. Existing shares resize: 50% president cert → 20%; each 25% cert → 10%
2. Share price moves right×2, up×1 from original regional par (sets the major par)
3. 6 new 10% IPO shares issued — forming the full 9-cert major structure (1×20% + 8×10%)
4. New major tokens added to charter (₤40, ₤60, ₤60, ₤80, ₤80, ₤80)
5. Post-conversion sell window: all players may sell, then buy shares of the new major
6. The player who triggered conversion must hold the 20% president cert at window close

**Major par values** (by original regional par):

| Regional par | Major par |
|-------------|-----------|
| £60 | £75 |
| £65 | £80 |
| £70 | £90 |
| £75 | £100 |
| £80 | £110 |
| £90 | £120 |

Track rights zone for the major = zone of the original regional. The converted major operates in the Major Phase from its next OR.

---

## Minor SR Merger §10.4 *(beta scope — not fully implemented)*

During the SR, a major may absorb a compatible minor:
- Minor must be reachable by an unlimited-city train from the major's network
- Minor's trains, track rights chit, and tokens transfer to the major
- Player receives negotiated cash or shares from the major's president
- Minors with ability A pay the bank (not the minor owner) at current share price
