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
      if command -v wget >/dev/null 2>&1; then
        wget -q --content-disposition \
          "https://api.ngc.nvidia.com/v2/resources/nvidia/ngc-apps/ngc_cli/versions/3.55.0/files/ngccli_linux.zip" \
          -O /tmp/ngccli_linux.zip
      else
        curl -sL \
          "https://api.ngc.nvidia.com/v2/resources/nvidia/ngc-apps/ngc_cli/versions/3.55.0/files/ngccli_linux.zip" \
          -o /tmp/ngccli_linux.zip
      fi
      unzip -o /tmp/ngccli_linux.zip -d "$HOME" >/dev/null 2>&1 || true
      chmod +x "$NGC_DIR/ngc" 2>/dev/null || true
      rm -f /tmp/ngccli_linux.zip
      echo "NGC CLI installed to $NGC_DIR"
    fi
  '';
}
