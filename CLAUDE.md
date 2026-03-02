# CLAUDE.md - Dotfiles Reference

## Overview

**Type:** Home Manager flake-based configuration
**Owner:** Alec Flowers
**Platform:** Linux (x86_64-linux) only
**Design:** Two profiles (lightweight / full) via separate flake homeConfigurations

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

| Name | User | Profile | Use Case |
|------|------|---------|----------|
| `local` | aflowers | lightweight | workstation |
| `local-full` | aflowers | full | workstation dev |
| `brev-vm` | ubuntu | lightweight | quick GPU sessions |
| `brev-vm-full` | ubuntu | full | long dev sessions |
| `brev-vm-gpu` | nvidia | lightweight | nvidia-user GPU |
| `brev-vm-root` | root | lightweight | root fallback |

## Key Patterns

- **extraSpecialArgs:** `user` and `homeDirectory` passed to all modules
- **Activation scripts:** Used for one-time setup (NGC CLI, p10k theme, zsh plugins, SSH keys)
- **Secrets:** Never in repo. Loaded from `~/.zshrc.local` at shell startup
- **Functions:** Sourced from `~/.zsh_functions/*.sh` at shell startup
- **PATH:** Set in `zsh.nix` initContent (ngc-cli, .local/bin, go, cuda)

## Makefile Targets

- `make install` - Install Nix
- `make vm` / `make vm-full` - Apply lightweight / full VM config
- `make local` / `make local-full` - Apply lightweight / full local config
- `make check` - Validate flake
- `make backup` - Backup existing dotfiles
