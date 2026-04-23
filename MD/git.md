---
title: Git & Documentation Setup
type: reference
---

# Git & Documentation Setup

## Repository Structure

```
/home/witzman/
    18xx/                        ← project root (NOT a git repo)
        18xx/                    ← main git repo (fork of tobymao/18xx)
        MD  →  symlink           ← points to /home/witzman/18xx-docs/MD/
        CLAUDE.md  →  symlink    ← points to /home/witzman/18xx-docs/CLAUDE.md
        coding_guidelines.txt
        rules/
        ...
    18xx-docs/                   ← git worktree, Documentation branch
        MD/
        CLAUDE.md
        ...
```

## Main Repo (`~/18xx/18xx/`)

Fork of the tobymao/18xx engine. All 18OE game implementation lives here.

| Remote | URL |
|---|---|
| `origin` | `git@github.com:Witzman/18xx.git` |
| `upstream` | `https://github.com/tobymao/18xx.git` |

Active branches: `18oe_fullmap`, `18oe_fullmapfix`, `master`, and others.

## Documentation Worktree (`~/18xx-docs/`)

A git worktree of the same repo, permanently checked out on the `Documentation` branch.
It is not a separate clone — it shares the `.git` object store with `~/18xx/18xx/`.
Note: it lives at `/home/witzman/18xx-docs/`, one level above the project root.

```bash
# How it was created:
git -C ~/18xx/18xx worktree add /home/witzman/18xx-docs Documentation
```

The `Documentation` branch contains `MD/` and `CLAUDE.md`. No other branch tracks them.

Remotes in the worktree:

| Remote | URL |
|---|---|
| `origin` | `git@github.com:Witzman/18xx.git` |
| `upstream` | `https://github.com/tobymao/18xx.git` |

## MD/ Symlink

`~/18xx/MD` is a symlink to `~/18xx-docs/MD/`:

```bash
# How it was created:
ln -s /home/witzman/18xx-docs/MD /home/witzman/18xx/MD
```

Because the symlink lives in `~/18xx/` (not inside the git repo), it is invisible to
git on all branches. The `MD/` files are always accessible regardless of which branch
the main repo is on.

## Working with Documentation Files

**Edit** any file via `~/18xx/MD/` or `~/18xx/CLAUDE.md` as normal — symlinks are transparent.

**Commit** changes from the worktree directory:

```bash
cd ~/18xx-docs
git add MD/filename.md        # or CLAUDE.md
git commit -m "describe change"
git push
```

Never commit these files from `~/18xx/18xx/` or any other branch.

## SSH Authentication

Both the main repo and the worktree use SSH:

```bash
git -C ~/18xx/18xx remote set-url origin git@github.com:Witzman/18xx.git
git -C ~/18xx-docs remote set-url origin git@github.com:Witzman/18xx.git
```

SSH public key is at `~/.ssh/id_ed25519.pub` and is registered on GitHub.
To add it to a new machine: GitHub → Settings → SSH and GPG keys → New SSH key.

## Recreating the Setup (if lost)

If the worktree or symlink needs to be rebuilt from scratch:

```bash
# 1. Add the worktree (outside the project root)
git -C ~/18xx/18xx worktree add /home/witzman/18xx-docs Documentation

# 2. Create the symlinks (inside the project root)
ln -s /home/witzman/18xx-docs/MD /home/witzman/18xx/MD
ln -s /home/witzman/18xx-docs/CLAUDE.md /home/witzman/18xx/CLAUDE.md
```

No `.gitignore` entries needed — the symlink is outside all git repos.
