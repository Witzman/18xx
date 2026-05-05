# 18OE — Common Commands

Quick reference for the commands you actually need during a development session.
Paths assume the standard setup described in `MD/git.md` (`~/18xx/18xx/` for code,
`~/18xx-docs/` for the Documentation worktree).

> **Caveat.** Some of these are unverified — they reflect the standard 18xx engine
> conventions and what `MD/workflow.md` mentions about Docker. If a command below
> doesn't match your local setup, edit it here so the next person doesn't trip
> over the same thing.

---

## Run the app locally

The 18xx engine is a Ruby/Sinatra web app. Standard local-dev pattern (verify
against `18xx/DEVELOPMENT.md` if anything fails):

```bash
# from ~/18xx/18xx/ — boot the dev server (Docker)
cd ~/18xx/18xx
docker compose up

# the app is then served at http://localhost:9292/  (port may vary)
```

To launch a 18OE game in the browser, use the title selector and pick *18OE* (full
game) or *18OEUKFR* (variant — out of scope for current work).

---

## Lint & style checks

```bash
cd ~/18xx/18xx
bundle exec rubocop lib/engine/game/g_18_oe/
```

Coding-guideline reminders:

- 130-character line limit for `.rb` files (see `coding_guidelines.txt`).
- No `puts` / `p` debugging in committed code.

---

## Tests

There are currently no 18OE specs. The full engine test suite lives in
`18xx/spec/`:

```bash
cd ~/18xx/18xx
bundle exec rspec
bundle exec rspec spec/path/to/single_spec.rb     # run one file
bundle exec rspec spec/path/to/single_spec.rb:42  # run one example
```

### Suggested smoke spec (not yet committed)

A 5-line spec at `spec/games/g_18_oe/smoke_spec.rb` would catch most accidental
breakage from refactors. Drop in:

```ruby
# spec/games/g_18_oe/smoke_spec.rb
require 'spec_helper'
require 'engine/game/g_18_oe/game'

describe Engine::Game::G18OE do
  it 'initialises a 4-player game without errors' do
    expect { described_class.new(%w[A B C D]) }.not_to raise_error
  end
end
```

Then run:

```bash
bundle exec rspec spec/games/g_18_oe/smoke_spec.rb
```

When this is committed, wire it as a pre-commit hook (see below).

---

## Pre-commit hook (recommended)

Once the smoke spec exists:

```bash
# in ~/18xx/18xx/ — install once
cat > .git/hooks/pre-commit <<'SH'
#!/usr/bin/env bash
set -euo pipefail
bundle exec rspec spec/games/g_18_oe/smoke_spec.rb
bundle exec rubocop lib/engine/game/g_18_oe/
SH
chmod +x .git/hooks/pre-commit
```

(Or replace with `lefthook` / `pre-commit` framework if the team adopts one.)

---

## Documentation commits

`MD/` is a symlink into the `~/18xx-docs/` worktree (Documentation branch). Always
commit doc changes from the worktree, never from a code branch. See `MD/git.md`
for the full setup.

```bash
cd ~/18xx-docs
git status                          # confirm what changed
git add MD/filename.md              # or `git add -A MD/`
git commit -m "describe change"
git push                            # pushes to Documentation branch on origin
```

---

## Branch reference

Code work is happening on `18oe_testgame`. `master` is unmodified upstream.
See `MD/status.md` §20 for outstanding upstream PRs.

```bash
cd ~/18xx/18xx
git branch -v                       # see all local branches
git checkout 18oe_testgame
```

---

## Quick file lookups

```bash
# all 18OE Ruby files
ls ~/18xx/18xx/lib/engine/game/g_18_oe/{,step/,round/}

# rules text (handy for grep)
less ~/18xx/18xx/rules/18OE_Rulebook_v_1.0.txt
less ~/18xx/18xx/rules/18OE_Playbook_v_1.0.txt
```

---

## Updating this file

When you learn a new command (or one of the commands above turns out to be
wrong), edit this file from the docs worktree and commit. Future-you will thank
you.
