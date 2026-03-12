# JJ vs Git Command Mapping Research

## Overview

This research covers the command mapping between Jujutsu (jj) and Git, based on the official documentation at https://docs.jj-vcs.dev/latest/git-command-table/

## Key Conceptual Differences

| Concept | Git | Jujutsu (jj) |
|---------|-----|--------------|
| Working copy | Modified files tracked separately | Automatically committed |
| Staging area | Index (staging area) exists | No index - uses commits instead |
| Branch tracking | Current branch | Bookmarks (no "current" bookmark) |
| Conflicts | Block commands | Can be committed, resolved later |
| Rewrite propagation | Manual rebase | Automatic descendant rebasing |

## Command Reference Table

### Repository Operations

| Git Command | JJ Command | Notes |
|-------------|------------|-------|
| `git init` | `jj git init [--no-colocate]` | |
| `git clone <source>` | `jj git clone <source>` | JJ can't clone non-Git repos |
| `git fetch` | `jj git fetch [--remote <remote>]` | |
| `git push --all` | `jj git push --all [--remote <remote>]` | |
| `git push <remote> <branch>` | `jj push --bookmark <name> [--remote <remote>]` | |
| `git remote add` | `jj git remote add` | |

### Status & Viewing

| Git Command | JJ Command | Notes |
|-------------|------------|-------|
| `git status` | `jj st` | |
| `git diff HEAD` | `jj diff` | |
| `git diff <rev>^ <rev>` | `jj diff -r <revision>` | |
| `git diff <rev>` | `jj diff --from <revision>` | Diff from rev to current |
| `git diff A B` | `jj diff --from A --to B` | |
| `git diff A...B` | `jj diff -r A..B` | |
| `git show <rev>` | `jj show <revision>` | |
| `git log --oneline --graph` | `jj log -r ::@` | Ancestors of current |
| `git log --oneline --graph --all` | `jj log -r 'all()'` or `jj log -r ::` | All commits |
| `git log -G <pattern>` | `jj log -r 'diff_lines(regex:pattern)'` | |
| `git ls-files --cached` | `jj file list` | |
| `git grep` | `grep $(jj file list)` or `rg --no-require-git` | |
| `git blame` | `jj file annotate` | |

### File Operations

| Git Command | JJ Command | Notes |
|-------------|------------|-------|
| `touch file; git add file` | `touch file` | Auto-tracked |
| `git rm filename` | `rm filename` | |
| `git rm --cached filename` | `jj file untrack filename` | Must match ignore pattern |
| Modify file | Same | Direct modification |

### Commit Operations

| Git Command | JJ Command | Notes |
|-------------|------------|-------|
| `git commit -a` | `jj commit` | Finishes WC commit |
| `git reset --hard` | `jj abandon` | Abandon current change |
| `git reset --soft HEAD~` | `jj squash --from @-` | Keep parent diff in WC |
| `git restore <paths>` | `jj restore <paths>` | Discard WC changes |
| `git commit --amend` | `jj describe` | Edit commit message |
| `git stash` | `jj new @-` | Temporarily put away change |

### Branch/Bookmark Operations

| Git Command | JJ Command | Notes |
|-------------|------------|-------|
| `git switch -c topic main` | `jj new main` | Start new change |
| `git checkout -b topic` | `jj new main` | |
| `git merge A` | `jj new @ A` | Merge into current |
| `git checkout v1.0` | `jj new v1.0` | Examine old revision |
| `git branch` | `jj bookmark list` or `jj b l` | |
| `git branch <name>` | `jj bookmark create <name> -r <revision>` | |
| `git branch -f <name> <rev>` | `jj bookmark move <name> --to <revision>` | |
| `git branch -d <name>` | `jj bookmark delete <name>` | |

### Rebase & Rewrite

| Git Command | JJ Command | Notes |
|-------------|------------|-------|
| `git rebase B A` | `jj rebase -b A -o B` | Move bookmark |
| `git rebase --onto B A^` | `jj rebase -s A -o B` | Move change + descendants |
| `git rebase -i` | `jj rebase -r C --before B` | Reorder (or `jj arrange`) |
| `git commit --amend -a` | `jj squash` | Move WC diff to parent |
| `git add -p; git commit --amend` | `jj squash -i` | Interactive squash |
| `git commit --fixup=X` | `jj squash --into X` | Squash into ancestor |
| `git rebase -i` (split) | `jj split` | Split WC commit |
| | `jj split -r <revision>` | Split arbitrary commit |
| | `jj diffedit -r <revision>` | Edit diff in change |
| `git cherry-pick` | `jj duplicate <source> -o <destination>` | Copy commit |

### Advanced Operations

| Git Command | JJ Command | Notes |
|-------------|------------|-------|
| | `jj op log` | Operation log (replaces reflog) |
| | `jj undo` | Undo last operation |
| | `jj op revert` | Revert earlier operation |
| `git revert` | `jj revert -r <revision> -B @` | Create revert commit |
| `git rev-parse --show-toplevel` | `jj workspace root` | Find repo root |

## Key Differences Summary

1. **No staging area**: JJ auto-commits the working copy. Use `jj split` to commit partial changes.

2. **No "current branch"**: JJ uses bookmarks but doesn't track a "current" one. Update bookmarks manually with `jj bookmark move`.

3. **Conflicts are committable**: JJ doesn't block on conflicts. Resolve with `jj squash` after editing files.

4. **Automatic rebasing**: Rewriting any commit automatically rebases all descendants.

5. **Operation log**: Replaces Git's reflog with atomic operation tracking. Use `jj undo`/`jj redo`.

## Aliases

Common short aliases in JJ:
- `jj b l` = `jj bookmark list`
- `jj b m` = `jj bookmark move`
- `jj st` = `jj status`

## Sources

- Official JJ Git comparison: https://docs.jj-vcs.dev/latest/git-comparison/
- JJ Git command table: https://docs.jj-vcs.dev/latest/git-command-table/
