# Before / after: waterfall minor reduced to £0 (fork PR 59)

Hotseat games. Load one with **New Game → Import hotseat game** and paste the file's content. Base `267887b74`, PR branch `c67ab8245`.

| File | Load on | What you see at the end |
|---|---|---|
| `before.json` (215 actions) | base and PR branch | Auction: the minors A, B and C cost £5, the next pass reduces them to £0 |
| `after.json` (216 actions) | PR branch | That pass is played: the next player gets the three minors for £0 (does not load on the base: `Cannot spend zero or negative money`) |

Seed 1, every player passes from the start; the last pass is action 216.

Rule: RB §7 and §7.1.

## Origin and limits

- No bots: only passes. Played locally.
- Checked by replaying the files in the engine on base and PR branch (MRI, and compiled with Opal).
- Not checked: the import in a real browser, and whether the other moves are rule-conform.
