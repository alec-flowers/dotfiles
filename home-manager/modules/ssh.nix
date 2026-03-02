{ config, pkgs, lib, ... }:

{
  programs.ssh = {
    enable = true;
    includes = [
      "~/.ssh/config.local"
      "~/.brev/ssh_config"
    ];
    matchBlocks = {
      "*" = {
        extraOptions = {
          "AddKeysToAgent" = "yes";
          "ServerAliveInterval" = "60";
          "ServerAliveCountMax" = "3";
        };
        controlMaster = "auto";
        controlPath = "~/.ssh/sockets/%r@%h-%p";
        controlPersist = "600";
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/gitlab_2026_01";
        identitiesOnly = true;
      };
      "gitlab-master.nvidia.com" = {
        hostname = "gitlab-master.nvidia.com";
        port = 12051;
        user = "git";
        identityFile = "~/.ssh/gitlab_2026_01";
        identitiesOnly = true;
      };
    };
  };

  # Ensure SSH control socket directory exists
  home.activation.sshSocketDir = ''
    mkdir -p ~/.ssh/sockets
  '';

  # Enable ssh-agent on Linux
  services.ssh-agent.enable = true;

  # Add keys to agent if not already loaded
  home.activation.sshAddKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    add_key_if_missing() {
      local key="$1"
      if [ -f "$key" ]; then
        if ! ssh-add -l 2>/dev/null | grep -q "$(basename "$key")"; then
          ssh-add "$key" 2>/dev/null || true
        fi
      fi
    }

    # Only if agent is running
    if ssh-add -l >/dev/null 2>&1 || [ $? -eq 1 ]; then
      add_key_if_missing "$HOME/.ssh/gitlab_2026_01"
    fi
  '';
}
