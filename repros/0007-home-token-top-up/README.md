# Before / after: owner tops up a minor's home token (fork PR 64)

Hotseat games. Load one with **New Game → Import hotseat game** and paste the file's content. Base `267887b74`, PR branch `61a7d137a`.

| File | Load on | What you see at the end |
|---|---|---|
| `before.json` (235 actions) | base and PR branch | Minor A was bought for £20 and has to place its home token; the UK and PHS zones cost £40 |
| `after.json` (236 actions) | PR branch | A places in Edinburgh, Bot 1 tops up £20 (does not load on the base: `A cannot lay token - cannot afford token on G26`) |

Seed 1: everyone passes until A costs £20, Bot 1 buys it, play goes on to A's home token (action 235).

Rule: RB §9.1 step 2 and §7; the top-up itself is the proposal of this PR, the rulebook is silent.

## Origin and limits

- Passes up to the purchase, then rule-based bots. Played locally.
- Checked by replaying the files in the engine (MRI) on base and PR branch.
- Not checked: the import in a browser, and whether the other moves are rule-conform.
