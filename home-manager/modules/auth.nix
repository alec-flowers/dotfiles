{ config, lib, pkgs, ... }:

# Generate tool-specific auth configs from ~/.secrets env vars.
# Runs during `home-manager switch`. Each script is idempotent.
# Note: activation scripts run under `set -eu`, so use ${VAR:-} for unset checks.

{
  home.activation.setupGhConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "''${GH_TOKEN:-}" ] && [ -f "$HOME/.secrets" ]; then
      . "$HOME/.secrets"
    fi
    if [ -z "''${GH_TOKEN:-}" ]; then
      echo "setupGhConfig: GH_TOKEN not set, skipping"
    else
      GH_DIR="$HOME/.config/gh"
      mkdir -p "$GH_DIR"
      cat > "$GH_DIR/hosts.yml" <<EOF
github.com:
    oauth_token: $GH_TOKEN
    user: alec-flowers
    git_protocol: ssh
EOF
      echo "setupGhConfig: wrote $GH_DIR/hosts.yml"
    fi
  '';

  home.activation.setupNgcConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "''${NGC_CLI_API_KEY:-}" ] && [ -f "$HOME/.secrets" ]; then
      . "$HOME/.secrets"
    fi
    if [ -z "''${NGC_CLI_API_KEY:-}" ]; then
      echo "setupNgcConfig: NGC_CLI_API_KEY not set, skipping"
    else
      NGC_DIR="$HOME/.ngc"
      mkdir -p "$NGC_DIR"
      cat > "$NGC_DIR/config" <<EOF
;WARNING - This is a machine generated file.  Do not edit manually.
;WARNING - To update local config settings, see "ngc config set -h"

[CURRENT]
apikey = $NGC_CLI_API_KEY
format_type = ascii
org = nvidian
team = dynamo-dev
EOF
      echo "setupNgcConfig: wrote $NGC_DIR/config"
    fi
  '';

  home.activation.setupGlabConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "''${GITLAB_TOKEN:-}" ] && [ -f "$HOME/.secrets" ]; then
      . "$HOME/.secrets"
    fi
    if [ -z "''${GITLAB_TOKEN:-}" ]; then
      echo "setupGlabConfig: GITLAB_TOKEN not set, skipping"
    else
      GLAB_DIR="$HOME/.config/glab-cli"
      mkdir -p "$GLAB_DIR"
      cat > "$GLAB_DIR/config.yml" <<EOF
git_protocol: ssh
glamour_style: dark
hosts:
    gitlab-master.nvidia.com:
        token: $GITLAB_TOKEN
        api_host: gitlab-master.nvidia.com
        git_protocol: ssh
        api_protocol: https
EOF
      echo "setupGlabConfig: wrote $GLAB_DIR/config.yml"
    fi
  '';

  home.activation.setupDockerNvcr = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -z "''${NGC_CLI_API_KEY:-}" ] && [ -f "$HOME/.secrets" ]; then
      . "$HOME/.secrets"
    fi
    DOCKER_BIN=""
    if command -v docker >/dev/null 2>&1; then
      DOCKER_BIN="docker"
    elif [ -x /usr/bin/docker ]; then
      DOCKER_BIN="/usr/bin/docker"
    fi
    if [ -z "''${NGC_CLI_API_KEY:-}" ]; then
      echo "setupDockerNvcr: NGC_CLI_API_KEY not set, skipping"
    elif [ -z "$DOCKER_BIN" ]; then
      echo "setupDockerNvcr: docker not found, skipping"
    elif ! $DOCKER_BIN info >/dev/null 2>&1; then
      echo "setupDockerNvcr: docker daemon not running, skipping"
    else
      echo "$NGC_CLI_API_KEY" | $DOCKER_BIN login nvcr.io -u '$oauthtoken' --password-stdin 2>/dev/null \
        && echo "setupDockerNvcr: logged into nvcr.io" \
        || echo "setupDockerNvcr: docker login failed (non-fatal)"
    fi
  '';
}
