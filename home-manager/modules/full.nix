{ config, lib, pkgs, ... }:

# Full-profile extras: custom zsh plugins, rust toolchain, modern CLI tools.
# Imported by *-full homeConfigurations only.

{
  imports = [
    ./rust.nix
    ./nvsec.nix
  ];

  # Additional packages for full profile
  home.packages = with pkgs; [
    awscli2
    azure-cli
    fzf
    kubectl
  ];

  # Clone zsh plugins if missing
  home.activation.cloneZshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PLUGIN_DIR="$HOME/.zsh-plugins"
    mkdir -p "$PLUGIN_DIR"

    clone_if_missing() {
      local repo="$1"
      local dest="$2"
      if [ ! -d "$dest" ]; then
        ${pkgs.git}/bin/git clone --depth 1 "$repo" "$dest" 2>/dev/null || true
      fi
    }

    clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions" \
      "$PLUGIN_DIR/zsh-autosuggestions"
    clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting" \
      "$PLUGIN_DIR/zsh-syntax-highlighting"
    clone_if_missing "https://github.com/zsh-users/zsh-history-substring-search" \
      "$PLUGIN_DIR/zsh-history-substring-search"
    clone_if_missing "https://github.com/marlonrichert/zsh-autocomplete" \
      "$PLUGIN_DIR/zsh-autocomplete"
  '';

  # Full-profile: source custom plugins
  programs.zsh.initContent = lib.mkAfter ''
    for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search zsh-autocomplete; do
      plugin_file="$HOME/.zsh-plugins/$plugin/$plugin.plugin.zsh"
      [ -f "$plugin_file" ] && source "$plugin_file"
    done
  '';
}
