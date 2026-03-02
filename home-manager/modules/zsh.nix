{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    completionInit = ''
      autoload -Uz compinit
      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit -u
      else
        compinit -C -u
      fi
    '';

    history = {
      size = 10000;
      save = 20000;
      ignoreDups = true;
      share = true;
    };

    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    shellAliases = {
      # Git shortcuts
      ga = "git add";
      gc = "git commit";
      gps = "git push";
      gs = "git status";
      gpl = "git pull";
      gf = "git fetch";
      gcb = "git checkout -b";
      gp = "git push";
      gll = "git log --oneline";
      gd = "git diff";
      gco = "git checkout";

      # Modern CLI aliases
      cat = "bat --style=plain --paging=never";
      ls = "eza -la --color=always --group-directories-first";
      l = "eza --color=always --group-directories-first";
      ll = "eza -la --color=always --group-directories-first";
      lt = "eza --tree";

      # Basic aliases
      d = "docker";
      dc = "docker compose";
      k = "kubectl";
      m = "make";
      tm = "tmux_auto_start";

      # Networking
      myip = "curl -s icanhazip.com";

      # venv
      venv = "source .venv/bin/activate";
    };

    initContent = lib.mkMerge [
      # Powerlevel10k instant prompt (must be first)
      (lib.mkOrder 500 ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        export PATH="$HOME/.local/bin:$PATH"

        # Source powerlevel10k directly (no framework overhead)
        P10K_THEME="$HOME/.zsh-plugins/powerlevel10k/powerlevel10k.zsh-theme"
        [[ -f "$P10K_THEME" ]] && source "$P10K_THEME"
      '')

      # Main configuration
      (lib.mkOrder 1000 ''
        # tmux session helper
        tmux_auto_start() {
          echo "Available tmux sessions:"
          tmux ls 2>/dev/null || echo "  (none)"
          echo "Enter session name to attach or create:"
          read session_name
          if ! tmux has-session -t "$session_name" 2>/dev/null; then
            tmux new-session -s "$session_name" -d
          fi
          tmux attach-session -t "$session_name"
        }

        # Source Cargo environment if it exists
        [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

        # Load portable secrets (API keys, tokens)
        [ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

        # Load machine-specific config (PATH, env vars)
        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

        # Load custom functions
        for f in "$HOME/.zsh_functions"/*.sh(N); do source "$f"; done

        # Load p10k config
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # Core plugins: autosuggestions (ghost text) + syntax highlighting
        for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
          plugin_file="$HOME/.zsh-plugins/$plugin/$plugin.plugin.zsh"
          [ -f "$plugin_file" ] && source "$plugin_file"
        done
      '')
    ];
  };

  # Clone zsh plugins if missing
  home.activation.installZshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PLUGIN_DIR="$HOME/.zsh-plugins"
    mkdir -p "$PLUGIN_DIR"

    clone_if_missing() {
      local repo="$1"
      local dest="$2"
      if [ ! -d "$dest" ]; then
        echo "Cloning $repo -> $dest"
        ${pkgs.git}/bin/git clone --depth 1 "$repo" "$dest"
      fi
    }

    # p10k theme
    clone_if_missing "https://github.com/romkatv/powerlevel10k" \
      "$PLUGIN_DIR/powerlevel10k"

    # Lightweight plugins (core)
    clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions" \
      "$PLUGIN_DIR/zsh-autosuggestions"
    clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting" \
      "$PLUGIN_DIR/zsh-syntax-highlighting"
  '';

  # Symlink p10k config
  home.file.".p10k.zsh".source = ../config/p10k.zsh;

  # Symlink functions directory
  home.file.".zsh_functions/aws_login.sh".source = ../functions/aws_login.sh;
  home.file.".zsh_functions/drun.sh".source = ../functions/drun.sh;
}
