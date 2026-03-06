{ config, lib, pkgs, ... }:

# Full-profile extras: custom zsh plugins, rust toolchain, modern CLI tools.
# Imported by *-full homeConfigurations only.

{
  imports = [
    ./rust.nix
    ./nvsec.nix
    ./claude-mcp.nix
  ];

  # Additional packages for full profile
  home.packages = with pkgs; [
    awscli2
    azure-cli
    k9s
    kubectl
    teleport
  ];

  # fzf with zsh integration (provides ctrl+r history search)
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Clone full-profile zsh plugins if missing (lightweight ones are in zsh.nix)
  home.activation.cloneFullZshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

    clone_if_missing "https://github.com/zsh-users/zsh-history-substring-search" \
      "$PLUGIN_DIR/zsh-history-substring-search"
    clone_if_missing "https://github.com/marlonrichert/zsh-autocomplete" \
      "$PLUGIN_DIR/zsh-autocomplete"
  '';

  home.sessionVariables = {
    KUBECONFIG = "$HOME/teleport-kubeconfig.yaml";
  };

  # Full-profile: source heavier plugins (after core plugins from zsh.nix)
  programs.zsh.initContent = lib.mkAfter ''
    for plugin in zsh-history-substring-search zsh-autocomplete; do
      plugin_file="$HOME/.zsh-plugins/$plugin/$plugin.plugin.zsh"
      [ -f "$plugin_file" ] && source "$plugin_file"
    done
  '';
}
