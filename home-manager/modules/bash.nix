{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historySize = 10000;
    historyFileSize = 20000;
    historyControl = [ "ignoredups" ];

    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };

    initExtra = ''
      # Source Cargo environment if it exists
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      # Source local machine-specific configs
      [ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
    '';
  };
}
