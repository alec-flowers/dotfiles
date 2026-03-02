# CLAUDE.md - Dotfiles Reference

## Overview

**Type:** Home Manager flake-based configuration
**Owner:** Alec Flowers
**Platform:** Linux (x86_64-linux) only
**Design:** Two profiles (core / full) generated for every user in the users list

## Architecture

```
home.nix (core packages + module imports)
├── modules/zsh.nix      # oh-my-zsh + p10k, built-in git plugin only
├── modules/bash.nix     # minimal fallback
├── modules/git.nix      # alec's git config, SSH signing
├── modules/vim.nix      # minimal vim
├── modules/ssh.nix      # github + gitlab matchBlocks
├── modules/tmux.nix     # ctrl+space, vi keys
└── modules/ngc.nix      # NGC CLI installer

modules/full.nix (imported additionally by *-full configs)
├── Clones custom zsh plugins (activation script)
├── Sources zsh-autosuggestions, syntax-highlighting, etc.
├── Imports modules/rust.nix (rustup)
└── Adds packages: fzf, fd, bat, eza
```

## Flake Configurations

Configs are generated as `{user}-{profile}` for every user × profile combo.

**Users:** aflowers, ubuntu, nvidia, root, dynamo (add new users in `home-manager/flake.nix` `users` list)
**Profiles:** core (`home.nix`), full (`home.nix` + `modules/full.nix`)

Examples: `aflowers-core`, `aflowers-full`, `ubuntu-core`, `root-full`, etc.

## Key Patterns

- **extraSpecialArgs:** `user` and `homeDirectory` passed to all modules
- **Activation scripts:** Used for one-time setup (NGC CLI, p10k theme, zsh plugins, SSH keys)
- **Secrets:** Never in repo. Loaded from `~/.zshrc.local` at shell startup
- **Functions:** Sourced from `~/.zsh_functions/*.sh` at shell startup
- **PATH:** Set in `zsh.nix` initContent (ngc-cli, .local/bin, go, cuda)

## Makefile Targets

- `make install` - Install Nix
- `make apply` - Apply config (defaults to `$(whoami)-core`)
- `make apply PROFILE=full` - Apply full profile for current user
- `make apply USER=root` - Apply core profile for a specific user
- `make check` - Validate flake
- `make backup` - Backup existing dotfiles
- `make bootstrap INSTANCE=name` - Bootstrap a remote instance
