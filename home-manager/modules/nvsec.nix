{ config, lib, pkgs, ... }:

# NVIDIA Security CLI (nvsec) - AWS credential management, artifact signing.
# Installed via pip from NVIDIA's internal PyPI registry.

{
  home.activation.installNvsec = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVSEC_VENV="$HOME/.nvsec-env"
    PYTHON="${pkgs.python3}/bin/python3"
    NVSEC_INDEX="https://urm.nvidia.com/artifactory/api/pypi/sw-cloudsec-pypi/simple"
    NVSEC_EXTRA="https://urm.nvidia.com/artifactory/api/pypi/sw-cftt-pypi-local/simple"

    if [ ! -d "$NVSEC_VENV" ]; then
      echo "Creating nvsec venv..."
      "$PYTHON" -m venv "$NVSEC_VENV"
    fi

    if "$NVSEC_VENV/bin/nvsec" version >/dev/null 2>&1; then
      echo "nvsec already installed, updating..."
    else
      echo "Installing nvsec..."
    fi
    "$NVSEC_VENV/bin/pip" install --upgrade nvsec \
      -i "$NVSEC_INDEX" \
      --extra-index-url "$NVSEC_EXTRA" \
      --quiet 2>/dev/null || true

    # Symlink into ~/.local/bin so it's on PATH
    mkdir -p "$HOME/.local/bin"
    ln -sf "$NVSEC_VENV/bin/nvsec" "$HOME/.local/bin/nvsec"
  '';
}
