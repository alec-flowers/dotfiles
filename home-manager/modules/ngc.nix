{ config, lib, pkgs, ... }:

# Download and install the NGC CLI if not already present.
# Requires NGC_API_KEY in ~/.zshrc.local for authenticated use.

{
  home.activation.installNgcCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NGC_DIR="$HOME/ngc-cli"
    if [ -x "$NGC_DIR/ngc" ]; then
      echo "NGC CLI already installed, skipping"
    else
      echo "Installing NGC CLI..."
      mkdir -p "$NGC_DIR"
      ${pkgs.curl}/bin/curl -sL \
        "https://api.ngc.nvidia.com/v2/resources/nvidia/ngc-apps/ngc_cli/versions/3.55.0/files/ngccli_linux.zip" \
        -o /tmp/ngccli_linux.zip
      ${pkgs.unzip}/bin/unzip -o /tmp/ngccli_linux.zip -d "$HOME" >/dev/null 2>&1 || true
      chmod +x "$NGC_DIR/ngc" 2>/dev/null || true
      rm -f /tmp/ngccli_linux.zip
      echo "NGC CLI installed to $NGC_DIR"
    fi
    # Symlink into ~/.local/bin so ngc-cli dir doesn't need to be on PATH
    mkdir -p "$HOME/.local/bin"
    ln -sf "$NGC_DIR/ngc" "$HOME/.local/bin/ngc"
  '';
}
