{ config, lib, pkgs, homeDirectory, ... }:

# Install Claude Code, Codex, and configure Claude Code preferences.

let
  atuinWrapper = "${homeDirectory}/dynamo-ai-workflows/tools/atuin-wrapper/atuin-wrapper.sh";
in
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

    # Configure Claude Code preferences
    CLAUDE_JSON="${homeDirectory}/.claude.json"
    if [ -f "$CLAUDE_JSON" ]; then
      ${pkgs.jq}/bin/jq '.verbose = true' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    fi

    CLAUDE_SETTINGS="${homeDirectory}/.claude/settings.json"
    ATUIN_WRAPPER="${atuinWrapper}"
    # Only set shell prefix if the wrapper script exists (repo cloned)
    if [ -f "$ATUIN_WRAPPER" ]; then
      ATUIN_JQ='| .env = (.env // {}) * {"CLAUDE_CODE_SHELL_PREFIX": $prefix}'
      ATUIN_ARGS="--arg prefix $ATUIN_WRAPPER"
    else
      ATUIN_JQ=""
      ATUIN_ARGS=""
    fi

    if [ -f "$CLAUDE_SETTINGS" ]; then
      ${pkgs.jq}/bin/jq $ATUIN_ARGS "
        .model = \"opus\" |
        .outputStyle = \"explanatory\"
        $ATUIN_JQ
      " "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
      echo "Claude Code preferences configured."
    else
      mkdir -p "${homeDirectory}/.claude"
      if [ -f "$ATUIN_WRAPPER" ]; then
        ${pkgs.jq}/bin/jq -n --arg prefix "$ATUIN_WRAPPER" '
          {model:"opus",outputStyle:"explanatory",env:{CLAUDE_CODE_SHELL_PREFIX:$prefix}}
        ' > "$CLAUDE_SETTINGS"
      else
        echo '{"model":"opus","outputStyle":"explanatory"}' | ${pkgs.jq}/bin/jq . > "$CLAUDE_SETTINGS"
      fi
      echo "Claude Code settings.json created."
    fi
  '';
}
