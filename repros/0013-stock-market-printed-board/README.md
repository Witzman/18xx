# Before / after: stock market grid of the printed Info Board (fork PR 66)

Hotseat games. Load one with **New Game → Import hotseat game** and paste the file's content. Base `267887b74`, PR branch `4c03464f6`.

| File | Load on | What you see at the end |
|---|---|---|
| `before.json` (100 actions) | base | Stock market tab: eight rows from £50, regional par markers in column 0 |
| `after.json` (100 actions) | PR branch | Stock market tab: nine rows from £30, regional par markers in column 2 |

Seed 1. The first 45 actions are identical. Par actions carry market coordinates, so each file (100 actions) loads only on its own engine.

Rule: Printed Info Board; RB §4 and §4.4.

## Origin and limits

- Rule-based bots. Played locally.
- Checked by replaying the files in the engine (MRI) on base and PR branch.
- Not checked: the import in a browser, and whether the other moves are rule-conform.
