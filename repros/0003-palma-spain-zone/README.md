# Before / after: Palma in the Spain track rights zone (fork PR 60)

Hotseat games. Load one with **New Game → Import hotseat game** and paste the file's content. Base `267887b74`, PR branch `b0c21d93f`.

| File | Load on | What you see at the end |
|---|---|---|
| `before.json` (176 actions) | base | Minor G (Spain zone) at Lay Track: Palma (AB27) is not offered |
| `before.json` (176 actions) | PR branch | Same position, Palma is offered |
| `after.json` (177 actions) | PR branch | G has laid tile 5 on Palma (the file also loads on the base, because the replay does not repeat the availability check) |

Seed 4, minor G with its home in Pôrto, first operating round, decision after action 176.

Rule: Printed map; playbook p. 9 and 11; RB §11.1.4 and §11.2.

## Origin and limits

- Rule-based bots, steered: RCP and MZA were not allowed to convert to majors. Played locally.
- Checked by replaying the files in the engine on base and PR branch (MRI, and compiled with Opal).
- Not checked: the import in a real browser, and whether the other moves are rule-conform.
