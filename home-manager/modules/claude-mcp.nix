{ config, lib, pkgs, homeDirectory, ... }:

# Clone dynamo-ai-workflows and configure Claude Code MCP servers.
# Imported by full profile only.

let
  repoDir = "${homeDirectory}/dynamo-ai-workflows";
  repoUrl = "git@gitlab-master.nvidia.com:mkosec/dynamo-ai-workflows.git";

  mcpServers = builtins.toJSON {
    linear = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
    };
    "compute-session" = {
      type = "stdio";
      command = "node";
      args = [ "${repoDir}/tools/compute-session/index.js" ];
    };
    "bash-mcp" = {
      type = "stdio";
      command = "node";
      args = [ "${repoDir}/tools/bash-mcp/index.js" ];
    };
  };
in
{
  home.activation.claudeMcp = lib.hm.dag.entryAfter [ "installAiTools" ] ''
    # Clone dynamo-ai-workflows if missing, pull latest if present
    if [ ! -d "${repoDir}" ]; then
      echo "Cloning dynamo-ai-workflows..."
      ${pkgs.git}/bin/git clone "${repoUrl}" "${repoDir}" || {
        echo "WARNING: Failed to clone dynamo-ai-workflows (SSH key missing?). Skipping MCP setup."
        exit 0
      }
    else
      echo "Updating dynamo-ai-workflows..."
      (cd "${repoDir}" && ${pkgs.git}/bin/git pull --ff-only origin main 2>/dev/null) || true
    fi

    # Install npm dependencies for MCP servers
    NPM="${pkgs.nodejs}/bin/npm"
    for tool_dir in "${repoDir}/tools/compute-session" "${repoDir}/tools/bash-mcp"; do
      if [ -f "$tool_dir/package.json" ] && [ ! -d "$tool_dir/node_modules" ]; then
        echo "Installing npm deps in $tool_dir..."
        (cd "$tool_dir" && "$NPM" install --no-fund --no-audit 2>/dev/null) || true
      fi
    done

    # Merge MCP servers into ~/.claude.json (global scope)
    CLAUDE_JSON="${homeDirectory}/.claude.json"
    if [ -f "$CLAUDE_JSON" ]; then
      ${pkgs.jq}/bin/jq --argjson servers '${mcpServers}' '
        .mcpServers = (.mcpServers // {}) * $servers
      ' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
      echo "Claude MCP servers configured."
    else
      echo "WARNING: ~/.claude.json not found. Install Claude Code first."
    fi

    # Now that the repo is cloned, set atuin wrapper if not already set
    CLAUDE_SETTINGS="${homeDirectory}/.claude/settings.json"
    ATUIN_WRAPPER="${repoDir}/tools/atuin-wrapper/atuin-wrapper.sh"
    if [ -f "$CLAUDE_SETTINGS" ] && [ -f "$ATUIN_WRAPPER" ]; then
      CURRENT_PREFIX=$(${pkgs.jq}/bin/jq -r '.env.CLAUDE_CODE_SHELL_PREFIX // ""' "$CLAUDE_SETTINGS")
      if [ "$CURRENT_PREFIX" != "$ATUIN_WRAPPER" ]; then
        ${pkgs.jq}/bin/jq --arg prefix "$ATUIN_WRAPPER" '
          .env = (.env // {}) * {"CLAUDE_CODE_SHELL_PREFIX": $prefix}
        ' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
        echo "Atuin wrapper configured for Claude Code."
      fi
    fi
  '';
}
