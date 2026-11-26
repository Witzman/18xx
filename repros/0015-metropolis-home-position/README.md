# Before / after: metropolis home position and the Right-of-Way tile (fork PR 68)

Hotseat games. Load one with **New Game → Import hotseat game** and paste the file's content. Base `267887b74`, PR branch `78249dcf6`.

| File | Load on | What you see at the end |
|---|---|---|
| `before.json` (241 actions) | base | MSP lays OE8 (rotation 0) on Sankt-Peterburg and takes home position 1: accepted |
| `before.json` (241 actions) | PR branch | Does not load: `MSP must choose a home token position that does not need the Right-of-Way green tile` |
| `after.json` (241 actions) | PR branch | Same tile, MSP takes home position 0 |

Seed 3, first operating round; the tile lay is action 240, the position action 241.

Rule: RB §11.1.9, last paragraph.

## Origin and limits

- Rule-based bots, steered: SB and MSP were not allowed to convert. Tile, rotation and position of the last two actions were chosen by hand. That position 1 needs the green tile is this branch's judgement, not checked against the map separately. Played locally.
- Checked by replaying the files in the engine (MRI) on base and PR branch.
- Not checked: the import in a browser, and whether the other moves are rule-conform.
