# 18xx Ruby Engine — Ability Types and `when:` Reference

Extracted from ENTITIES_AUDIT.md and WHEN_FIELD_DESIGN.md.
Covers all 31 ability types found across 112 entities.rb files, and the complete
`when:` vocabulary. Focused on what is needed for 18OE minor/private abilities.

---

## 1. Ability Type Frequency Table

Found across 112 entities.rb files in the tobymao engine:

| Ability type | Occurrences | Games | Key fields |
|---|---|---|---|
| `exchange` | 260 | 31 | `corporations:`, `from:`, `when:` |
| `tile_lay` | 232 | 59 | `count:`, `when:`, `free:`, `tiles:`, `hexes:`, `consume_tile_lay:`, `closed_when_used_up:`, `reachable:` |
| `blocks_hexes` | 180 | 40 | `hexes:` |
| `no_buy` | 175 | 35 | (no extra fields; sets corp as non-purchaseable) |
| `shares` | 124 | 43 | `shares:` (e.g. `'PRR_0'`) |
| `close` | 108 | 38 | `when:`, `corporation:`, `on_phase:` |
| `revenue_change` | 92 | 14 | `revenue:`, `on_phase:` |
| `assign_hexes` | 82 | 34 | `hexes:` |
| `reservation` | 78 | 11 | `hexes:` |
| `hex_bonus` | 54 | 10 | `hexes:`, `amount:` |
| `token` | 53 | 27 | `price:`, `count:`, `corporation:` |
| `base` | 50 | 8 | `description:` |
| `tile_discount` | 44 | 28 | `terrain:`, `discount:` |
| `assign_corporation` | 34 | 21 | `corporations:` |
| `blocks_hexes_consent` | 32 | 4 | (blocking released when owner consents — used by concessions) |
| `description` | 21 | 8 | `description:` (18OE: minor associated-major text) |
| `choose_ability` | 19 | 6 | (no standard fields) |
| `manual_close_company` | 19 | 1 | (no standard fields) |
| `sell_company` | 19 | 2 | (no standard fields) |
| `train_discount` | 16 | 12 | `discount:`, `trains:` (train types to discount) |
| `teleport` | 16 | 12 | `hexes:`, `tiles:` |
| `tile_income` | 10 | 9 | (no standard fields) |
| `train_limit` | 9 | 6 | (no standard fields) |
| `generic` | 8 | 1 | `desc:` |
| `additional_token` | 7 | 7 | (no standard fields) |
| `train_buy` | 6 | 6 | (no standard fields) |
| `acquire_company` | 6 | 2 | (no standard fields) |
| `borrow_train` | 2 | 2 | (no standard fields) |
| `blocks_partition` | 2 | 2 | (no standard fields) |
| `train_scrapper` | 1 | 1 | (no standard fields) |
| `purchase_train` | 1 | 1 | (no standard fields) |

---

## 2. Abilities Most Relevant to 18OE

### Minor special abilities (§7 openpoints.md) — ability types needed:

| Minor | Desc | Ability types to use |
|---|---|---|
| A — Silver Banner | Bank pays major treasury = share value on merge | `base` with custom `description:` + hook in `game.rb#merge_minor` |
| B — Orange Scroll | Track upgrades cost 1 tile point (not cities/grand/metro) | `tile_discount` with `discount: 2` terrain condition; or custom step override |
| C — Golden Bell | President chooses operating position each OR | `choose_ability` + custom `operating_order` hook |
| D — Green Junction | Places token in non-metro city; £20/£40 bonus to trains | `token` (free placement) + `hex_bonus` (phase-conditional) |
| E — Blue Coast | 33% discount on blue terrain; +1 tile point in blue terrain | `tile_discount` (terrain: water) + `tile_lay` (count extra) |
| F — White Peak | 33% discount on green terrain; +1 tile point in green terrain | `tile_discount` (terrain: mountain) + `tile_lay` (count extra) |
| G — Indigo Foundry | +2 tile points per OR | `tile_lay` with `count: 2, when: 'track'` |
| H — Great Western Steamship | Reduces sea zones counted by 1 (Phase 1-6) or 2 (Phase 7-8) | Custom game hook; no standard ability type |
| J — Grey Locomotive Works | 10% discount on all train purchases | `train_discount` |
| K — Vermilion Seal | Mail contract: revenue to treasury each OR | `hex_bonus` or custom `extra_revenue` hook |
| L — Krasnaya Strela | +1+1 marker on assigned train each OR | Custom game hook; no standard type |
| M — CIWL | 10 Pullman cars | Custom Pullman asset; no standard ability type |

### Private special abilities (§8 openpoints.md) — ability types needed:

| Private | Desc | Ability type |
|---|---|---|
| Wien Südbahnhof | Free station token placement | `token` with `price: 0, when: 'token'` |
| Barclay, Bevan, Barclay & Tritton | Re-set par / reserve share / prevent DROP | `choose_ability` (3 options) |
| Star Harbor Trading Co. | Port token in port city | `token` + custom `assign_hexes` |
| Central Circle Transport Corp. | Token in non-port city as town | `token` + `hex_bonus` |
| White Cliffs Ferry | Token on Lille at Phase 5 | `tile_lay` + phase-trigger logic |
| Hochberg Mining & Lumber | Token in rough terrain hex; track restriction | `assign_hexes` + custom track restriction |
| Brandt & Brandau, Engineers | 4 tokens, 2/OR, free yellow tile | `tile_lay` (free=true, count:4, when: 'track') |
| Swift Metropolitan Line | Protects one 2+2 train from train limit | Custom game hook |

---

## 3. Ability Structure in Ruby (`entities.rb`)

Standard ability hash structure:

```ruby
{
  type: 'tile_lay',           # required: ability type string
  owner_type: 'player',       # optional: 'player' | 'corporation'
  when: 'track',              # optional: string or array of strings
  count: 2,                   # optional: number of uses; omit = unlimited
  hexes: %w[A1 B2],           # optional: hex restriction
  tiles: %w[57 58],           # optional: tile number restriction
  free: true,                 # optional: waives tile cost
  closed_when_used_up: true,  # optional: close company when count → 0
  reachable: true,            # optional: must be reachable from company's home
  consume_tile_lay: true,     # optional: consumes one of corp's normal lay slots
  terrain: 'mountain',        # optional (on tile_discount): terrain type
  discount: 20,               # optional (on tile_discount/train_discount): amount
  trains: %w[2+2 3+3],        # optional (on train_discount): train types
  corporations: %w[GWR LNWR], # optional (on exchange/token/assign_corp)
  from: 'par',                # optional (on exchange): source
  description: 'text',        # optional (on base/description/generic)
  price: 0,                   # optional (on token): token placement cost
  corporation: 'GWR',         # optional (on token/close): specific corp
  on_phase: 'Phase 4',        # optional (on close/revenue_change): phase trigger
  revenue: 20,                # optional (on revenue_change): new value
  amount: 30,                 # optional (on hex_bonus): bonus amount
}
```

---

## 4. `when:` Field Complete Vocabulary

Source: `lib/engine/game/base.rb#ability_right_time?`; 649 occurrences across 75 games.

### 4A — OR Step-Scoped (active during a specific OR step)

| Value | Active when | Ability types |
|---|---|---|
| `'track'` | `Step::Track` is active | `tile_lay`, `tile_discount` |
| `'special_track'` | `Step::SpecialTrack` is active | `tile_lay`, `teleport` |
| `'token'` | `Step::Token` is active | `token` |
| `'special_token'` | `Step::SpecialToken` is active | `token`, `teleport` |
| `'route'` | `Step::Route` is active | `generic` |
| `'track_and_token'` | `Step::TrackAndToken` is active | `tile_lay`, `token` |
| `'buy_train'` | `Step::BuyTrain` is active | `train_discount` |
| `'buying_train'` | During train purchase (alias for buy_train) | `train_discount` |
| `'single_depot_train_buy'` | Variant buy train step | `train_discount` |
| `'dividend'` | `Step::Dividend` is active | `generic`, `revenue_change` |
| `'exchange'` | SR `Step::Exchange` is active | `exchange` |

### 4B — OR Turn-Scoped (active during owning entity's OR turn)

| Value | Condition |
|---|---|
| `'owning_corp_or_turn'` | OR active AND current operator is ability's corp (155 occurrences) |
| `'owning_player_or_turn'` | OR active AND current operator's president is ability's player |
| `'owning_player_track'` | OR active AND president == ability.player AND in Track step |
| `'owning_player_token'` | OR active AND president == ability.player AND in Token step |
| `'or_between_turns'` | OR active AND `!current_operator_acted` (between corps' turns) |
| `'or_start'` | OR active AND `@round.at_start` (before any corp operates) |

### 4C — SR Turn-Scoped

| Value | Condition |
|---|---|
| `'owning_player_sr_turn'` | SR active AND current entity is ability's player (155 occurrences) |
| `'stock_round'` | SR active, any player, any turn |

### 4D — Event-Triggered (close ability `when:` only)

Used exclusively on `type: 'close'` abilities. These are game events, not round steps.

| Value | Triggered by |
|---|---|
| `'bought_train'` | `base.rb#buy_train` → `close_companies_on_event!(operator, 'bought_train')` |
| `'ran_train'` | `step/dividend.rb` → `close_companies_on_event!(entity, 'ran_train')` |
| `'operated'` | `step/dividend.rb#pass!` → `close_companies_on_event!(entity, 'operated')` |
| `'par'` | `base.rb#after_par` → `close_companies_on_event!(corporation, 'par')` |
| `'sold'` | `step/buy_company.rb` fires `'sold'` abilities |
| `'auction_end'` | Game-specific (g_1828): at end of initial auction |
| `'has_train'` | Revenue-change at OR start when corp has trains (1817 only) |

### 4E — Meta / Any-Round

| Value | Meaning |
|---|---|
| `'any'` | Usable at any time in any round. Short-circuits all other checks. |

### Always-Valid Values (never need validation)

These 9 values have no step prerequisite and are valid in any game with ORs or SRs:
`any`, `owning_corp_or_turn`, `owning_player_or_turn`, `owning_player_track`,
`owning_player_token`, `owning_player_sr_turn`, `stock_round`,
`or_between_turns`, `or_start`

---

## 5. `description` Ability (18OE minor association pattern)

The `description` ability is used in 18OE (and 1822) to associate a minor with a major:

```ruby
# In CORPORATIONS for a minor:
abilities: [{ type: 'description', description: 'Associated minor for GWR' }]
```

The 18OE codebase uses `par_via_exchange` (wired in `setup` via sym match) rather
than this description text. The description text in entities.rb is the human-readable
rulebook text for each minor's ability (already filled in for all 12 minors).

The `description` ability in game context also appears without a matching special
engine hook — the description is displayed in the UI and checked in some implementations
via `entity.abilities(:description).first&.description`.

---

## 6. `blocks_hexes_consent` vs `blocks_hexes`

- `blocks_hexes`: unconditional — hex is blocked until company is purchased or closed
- `blocks_hexes_consent`: blocking released when the owning player consents (used for
  concession cards — blocking released when concession is transferred or major is parred)

18OE concession cards (CON1–CON10) should use `blocks_hexes_consent` per the 1822
family pattern.

---

## 7. Exchange Ability (`from:` field values)

The `from:` field on `exchange` abilities specifies the share source:
- `'par'` — concession pattern: company exchanged to float a corporation at par price
- `'ipo'` — exchange for a share from IPO (initial offering)
- `'market'` — exchange for a share from the secondary market
- `%w[ipo market]` — either source (Ruby array notation)
- `%i[reserved]` — reserved share (less common)

18OE concessions use `from: 'par'` per the standard 1822/1866 concession pattern.

---

*Sources: ENTITIES_AUDIT.md (2026-04-19), WHEN_FIELD_DESIGN.md (2026-04-19),
lib/engine/game/base.rb, lib/engine/ability/base.rb, lib/engine/ability/tile_lay.rb*
