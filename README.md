# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). The dotfile source tree
lives under [`home/`](home/) (configured via [`.chezmoiroot`](.chezmoiroot)).

## Install

```sh
./bootstrap.sh
```

This installs Homebrew (if missing), runs `brew bundle` against the
[`Brewfile`](Brewfile), and then runs `chezmoi init --apply` pointing at
this repository so all dotfiles are deployed and the post-apply scripts
under [`home/`](home/) run (default shell, fisher plugins, vim plugins).

## Day-to-day

- Edit a managed file in place at its target location (e.g. `~/.gitconfig`)
  and run `chezmoi re-add` to pull the change back into this repo, or edit
  the source directly under `home/` and run `chezmoi apply`.
- See pending changes: `chezmoi diff`.
- Add a new file: `chezmoi add ~/.somefile`.
