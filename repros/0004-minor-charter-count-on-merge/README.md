# Before / after: merged minor's charter and the certificate limit (fork PR 61)

Hotseat games. Load one with **New Game → Import hotseat game** and paste the file's content. Base `267887b74`, PR branch `6021ef241`.

| File | Load on | What you see at the end |
|---|---|---|
| `before.json` (458 actions) | base | C has merged into CHN, the token decision is open: Bot 1 holds 17 of 48 certificates |
| `after.json` (458 actions) | PR branch | Same history: Bot 1 holds 16 of 48 |

Seed 1, stock round in Train Phase 3; both files have the same 458 actions, the difference is the certificate count each engine computes.

Rule: RB §10.5 and §4.1.

## Origin and limits

- Rule-based bots, steered: no majors before Phase 3, 3 trains and mergers preferred. Played locally.
- Checked by replaying the files in the engine on base and PR branch (MRI, and compiled with Opal).
- Not checked: the import in a real browser, and whether the other moves are rule-conform.
