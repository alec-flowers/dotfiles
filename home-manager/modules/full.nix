{ config, lib, pkgs, ... }:

# Full-profile extras: custom zsh plugins, rust toolchain, modern CLI tools.
# Imported by *-full homeConfigurations only.

{
  imports = [
    ./rust.nix
  ];

  # Additional packages for full profile
  home.packages = with pkgs; [
    fzf
  ];

  # Clone oh-my-zsh custom plugins if missing
  home.activation.cloneZshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZSH_CUSTOM="''${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    clone_if_missing() {
      local repo="$1"
      local dest="$2"
      if [ ! -d "$dest" ]; then
        echo "Cloning $repo ..."
        git clone --depth 1 "$repo" "$dest" 2>/dev/null || true
      fi
    }

    clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions" \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting" \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    clone_if_missing "https://github.com/zsh-users/zsh-history-substring-search" \
      "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    clone_if_missing "https://github.com/marlonrichert/zsh-autocomplete" \
      "$ZSH_CUSTOM/plugins/zsh-autocomplete"
  '';

  # Full zsh config additions (custom plugins)
  programs.zsh.initContent = lib.mkAfter ''
    # Full-profile: enable custom plugins if present
    ZSH_CUSTOM="''${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search zsh-autocomplete; do
      plugin_file="$ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh"
      [ -f "$plugin_file" ] && source "$plugin_file"
    done

  '';
}
