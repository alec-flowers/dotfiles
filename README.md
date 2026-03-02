# dotfiles

Forked from [ishandhanani/dotfiles](https://github.com/ishandhanani/dotfiles).

Nix + Home Manager dotfiles for reproducible dev environments on Brev GPU instances and local workstations.

## Quick Start — Brev Instance (one command from local)

```bash
cd ~/dotfiles

# Lightweight (fast GPU sessions)
make bootstrap INSTANCE=my-gpu-box

# Full dev environment
make bootstrap INSTANCE=my-gpu-box PROFILE=full
```

This copies your SSH key + secrets, installs Nix, clones dotfiles, and applies the config — all over your existing SSH tunnel.

## Quick Start — Local / Manual

```bash
git clone git@github.com:alec-flowers/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install              # Install Nix (first time only, restart terminal after)
make apply                # Apply core config for current user
make apply PROFILE=full   # Apply full config for current user
```

## Profiles

| Command | Profile | Description |
|---------|---------|-------------|
| `make apply` | Core | Defaults to `$(whoami)-core` |
| `make apply PROFILE=full` | Full | Full profile for current user |
| `make apply USER=root` | Core | Core profile for a specific user |
| `make apply USER=root PROFILE=full` | Full | Full profile for a specific user |
| `make check` | - | Validate flake |

**Core:** oh-my-zsh + p10k, tmux, vim, git, core CLI tools, NGC CLI, bat, fd, eza.

**Full:** Everything in core + custom zsh plugins (autosuggestions, syntax-highlighting, history-substring-search, autocomplete), Rust toolchain, fzf.

## Machine Config vs Portable Secrets

Two separate files, sourced in order:

- **`~/.zshrc.local`** — Machine-specific (PATH, HF_HOME, STORAGE, etc.). Each machine gets its own. Never copied.
- **`~/.secrets`** — Portable tokens (GITLAB_TOKEN, NGC_API_KEY, HF_TOKEN). Copy to new instances.

`make bootstrap` handles copying automatically. For manual setup, see templates in `home-manager/config/`.

## Structure

```
home-manager/
├── flake.nix           # 6 Linux configs (3 light + 3 full)
├── home.nix            # Core packages + module imports
├── modules/
│   ├── zsh.nix         # oh-my-zsh + p10k (built-in git plugin only)
│   ├── bash.nix        # Minimal fallback shell
│   ├── git.nix         # Git config + SSH signing
│   ├── vim.nix         # Minimal vim
│   ├── ssh.nix         # GitHub + GitLab matchBlocks
│   ├── tmux.nix        # Ctrl+Space prefix, vi keys
│   ├── ngc.nix         # NGC CLI auto-installer
│   ├── rust.nix        # Rustup installer (full profile only)
│   └── full.nix        # Custom zsh plugins, fzf, bat, eza, fd
├── config/
│   ├── p10k.zsh        # Powerlevel10k config
│   ├── zshrc.local.template    # Machine-specific env (never copy)
│   └── secrets.template        # Portable tokens (copy to instances)
└── functions/
    └── aws_login.sh    # AWS/nvsec login helper
```
