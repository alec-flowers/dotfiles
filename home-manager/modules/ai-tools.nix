{ config, lib, pkgs, ... }:

# Install Claude Code (standalone binary) and OpenAI Codex (via npm).

{
  home.packages = with pkgs; [
    nodejs
  ];

  home.activation.installAiTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Claude Code — standalone installer (self-contained ELF binary, no Node needed)
    if [ -x "$HOME/.local/bin/claude" ] && "$HOME/.local/bin/claude" --version >/dev/null 2>&1; then
      echo "Claude Code already installed, updating..."
    else
      echo "Installing Claude Code..."
    fi
    ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1 || true

    # Codex — requires Node, install via npm
    NPM="${pkgs.nodejs}/bin/npm"
    export npm_config_prefix="$HOME/.local"
    if command -v codex >/dev/null 2>&1; then
      echo "Codex already installed, updating..."
      "$NPM" install -g "@openai/codex" >/dev/null 2>&1 || true
    else
      echo "Installing Codex..."
      "$NPM" install -g "@openai/codex" >/dev/null 2>&1 || true
    fi
  '';
}
