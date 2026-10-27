# AGENTS.md — working rules

Project: **DesktopIdentifier** (Delphi 12, Win32). VCL configurator and startup
program without VCL. Context, build and usage in [README.md](README.md); history
in [docs/FASE-1.md](docs/FASE-1.md), [docs/FASE-2.md](docs/FASE-2.md) and
[docs/FASE-3.md](docs/FASE-3.md).

## Git is controlled by the user

The user is the only one who commits, and does so from **GitHub Desktop**. An
agent must not:

- Run `git add` / `git stage` or stage the index in any way.
- Run `git commit` in any variant (`-a`, `--amend`, with paths, etc.).
- Run `git push`, `git pull`, `git fetch`, `git reset`, `git revert`,
  `git restore`, `git checkout`, `git stash`, `git merge`, `git rebase`,
  `git cherry-pick`, `git tag`, or create or delete branches.
- Generate commit messages: Copilot generates them from GitHub Desktop.
- List or summarize changes (modified files or functional changes): the user
  sees them in GitHub Desktop.

It may:

- Use read-only Git commands (`git status`, `git diff`, `git log`, `git show`)
  if it needs context, without modifying anything.
- Edit files and leave them **unstaged** in the working tree.

## Delivery

- Do not produce a list or summary of changes, neither of files nor of
  functionality. A short confirmation that the task is done is enough.
- Only give details if the user explicitly asks for them.
- If a task needs a commit, stop and let the user do it.

## Build

- `Compilar.cmd --no-pause` builds both executables into `bin\`.
- `Configurar.cmd` opens the configurator.
- There are no automated tests; verification is manual.
