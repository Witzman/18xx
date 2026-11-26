# Before / after: level 3 train beside a reserved 2+2 (fork PR 63)

Two hotseat games with the same history. Load one with **New Game → Import hotseat game** and paste the
file's content.

| File | Engine | What you see at the end |
|---|---|---|
| `before.json` (963 actions) | base `267887b74` | MZA is at Buy Trains with £251 and owns one 2+2. The depot offers only the reserved 2+2, so MZA can buy nothing. |
| `before.json` | PR branch `fe732bfd0` | Same position, the depot offers the 2+2 and a 3 train. |
| `after.json` (964 actions) | PR branch `fe732bfd0` | MZA buys the 3 train for £200 and Phase 3 starts. |

`after.json` does not load on the base: `Not a buyable train: 3-0`.

## How the position arises

- Action 375: MIDI is forced to convert to a national (§11.6.4) before it has bought its reserved 2+2.
- One 2+2 stays in the depot. A national buys nothing there, and all other railroads have met their
  train obligation, so on the base no level 3 train is ever offered.
- Action 443 is the first Buy Trains decision where base and PR branch offer different trains.
  Action 963 is used here because the railroad can afford the 3 train.
- Continued on the base to action 3000 (turn 9), the game is still in Phase 2.

Rule: RB §8.3 and §11.6, level 3 trains may be bought "even if there are remaining level 2 trains reserved
for purchase by newly floated minors and regionals" (after the first OR, once the Major RR Phase has begun).

## MIDI's conversion

MIDI's conversion matches §11.6.4: a trainless major with £80, its president £9, the only train on offer the
£100 2+2. It follows £80 of track spending in its first OR as a major (it expanded from a regional with
£160 before that OR; actions 369 to 372). The §11.6.5 spending guard is read as covering minors and regionals
only, as the engine does. The fix does not depend on this: the §8.3 / §11.6 exception holds for any 2+2 still
reserved.

## Origin and limits

- Played by rule-based bots (3 seats, seed 1), run locally. The engine was not modified for `before.json`.
- Checked by replaying the files in the engine (MRI, and compiled with Opal): `before.json` on both commits,
  `after.json` on both (fails on the base as stated above).
- Not checked: the import in a real browser, whether each bot move is rule-conform, and the sea zone count behind
  the three track fees.
