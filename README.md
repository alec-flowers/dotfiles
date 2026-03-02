# dotfiles

Forked from [ishandhanani/dotfiles](https://github.com/ishandhanani/dotfiles).

Nix + Home Manager dotfiles for reproducible dev environments on Brev GPU instances and local workstations.

## Quick Start

```bash
# Clone
git clone git@github.com:alec-flowers/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install Nix (first time only)
make install
# Restart terminal after Nix install

# Lightweight (fast GPU sessions)
make vm

# Full dev environment (adds custom zsh plugins, rust, fzf, bat, eza, fd)
make vm-full
```

## Profiles

| Target | Profile | User Detection |
|--------|---------|---------------|
| `make local` | Lightweight | aflowers |
| `make local-full` | Full | aflowers |
| `make vm` | Lightweight | ubuntu / nvidia (auto) |
| `make vm-full` | Full | ubuntu |
| `make check` | Validate | - |

**Lightweight:** oh-my-zsh + p10k, tmux, vim, git, core CLI tools, NGC CLI.

**Full:** Everything in lightweight + custom zsh plugins (autosuggestions, syntax-highlighting, history-substring-search, autocomplete), Rust toolchain, fzf, fd, bat, eza.

## Machine Config vs Portable Secrets

Two separate files, sourced in order:

- **`~/.zshrc.local`** — Machine-specific (PATH, HF_HOME, STORAGE, etc.). Each machine gets its own. Never copied.
- **`~/.secrets`** — Portable tokens (GITLAB_TOKEN, NGC_API_KEY, HF_TOKEN). Copy to new instances.

```bash
# Copy portable files to a new Brev instance:
brev copy ~/.secrets INSTANCE:~/.secrets
brev copy ~/.ssh/gitlab_2026_01 INSTANCE:~/.ssh/
brev copy ~/.ssh/config.local INSTANCE:~/.ssh/config.local
```

See `home-manager/config/zshrc.local.template` and `secrets.template` for templates.

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
│   ├── secrets.template        # Portable tokens (copy to instances)
│   └── ssh-config.local.template
└── functions/
    └── aws_login.sh    # AWS/nvsec login helper
```
