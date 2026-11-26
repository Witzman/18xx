# Before / after: deferred home token charged twice (fork PR 65)

Hotseat games. Load one with **New Game → Import hotseat game** and paste the file's content. Base `78249dcf6`, PR branch `0c3575e10`.

| File | Load on | What you see at the end |
|---|---|---|
| `before.json` (252 actions) | base (PR 68's branch) | MSP places its deferred home token and pays £10 again: cash £150 |
| `after.json` (252 actions) | PR branch | Same history: the placement is free, cash £160 |

Seed 1, first operating round, action 252. Both files have the same actions; the cash differs by engine. MSP is a major here (it converted after floating as a regional). The base also stands for master, which shows £150 too.

Rule: RB §9.2 step 4 and §11.1.9.

## Origin and limits

- Rule-based bots. Played locally.
- Checked by replaying the files in the engine (MRI) on base and PR branch.
- Not checked: the import in a browser, and whether the other moves are rule-conform.
