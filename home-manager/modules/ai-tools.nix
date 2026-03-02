{ config, lib, pkgs, ... }:

# Install Claude Code and OpenAI Codex CLI tools via npm.

{
  home.packages = with pkgs; [
    nodejs
  ];

  home.activation.installAiTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NPM="${pkgs.nodejs}/bin/npm"

    install_or_update() {
      local pkg="$1"
      local cmd="$2"
      if command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd already installed, updating..."
        "$NPM" install -g "$pkg" >/dev/null 2>&1 || true
      else
        echo "Installing $cmd..."
        "$NPM" install -g "$pkg" >/dev/null 2>&1 || true
      fi
    }

    export npm_config_prefix="$HOME/.local"

    install_or_update "@anthropic-ai/claude-code" "claude"
    install_or_update "@openai/codex" "codex"
  '';
}
