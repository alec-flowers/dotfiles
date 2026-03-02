#!/usr/bin/env bash
# test-setup.sh — Verify dotfiles setup is complete and functional.
# Usage: bash tests/test-setup.sh
# Exit 0 if all pass, 1 if any fail.

set -euo pipefail

# Source secrets so tests work in non-login shells
if [ -f "$HOME/.secrets" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.secrets"
fi

# --- Colors ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); printf "  ${GREEN}PASS${NC}  %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  ${RED}FAIL${NC}  %s\n" "$1"; }
skip() { SKIP=$((SKIP + 1)); printf "  ${YELLOW}SKIP${NC}  %s\n" "$1"; }

section() { printf "\n${BLUE}=== %s ===${NC}\n" "$1"; }

# --- Nix Packages ---
section "Nix Packages"
for cmd in git curl wget jq rg htop tmux gh glab git-lfs gpg bat fd eza uv; do
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd on PATH"
  else
    fail "$cmd on PATH"
  fi
done

# --- Shell ---
section "Shell"
if command -v zsh >/dev/null 2>&1; then
  pass "zsh available"
else
  fail "zsh available"
fi

if [ -f "$HOME/.p10k.zsh" ]; then
  pass "p10k config exists"
else
  fail "p10k config exists"
fi

if [ -d "$HOME/.zsh-plugins/powerlevel10k" ]; then
  pass "p10k theme installed"
else
  fail "p10k theme installed"
fi

# --- SSH ---
section "SSH"
SSH_KEY="$HOME/.ssh/gitlab_2026_01"
if [ -f "$SSH_KEY" ]; then
  perms=$(stat -c '%a' "$SSH_KEY" 2>/dev/null || stat -f '%Lp' "$SSH_KEY" 2>/dev/null)
  if [ "$perms" = "600" ]; then
    pass "SSH key exists + correct permissions (600)"
  else
    fail "SSH key permissions ($perms, expected 600)"
  fi
else
  fail "SSH key exists ($SSH_KEY)"
fi

if ssh-add -l >/dev/null 2>&1; then
  pass "SSH agent running"
elif pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  pass "SSH agent running (process found, no socket in this shell)"
elif [ -S "${SSH_AUTH_SOCK:-}" ]; then
  pass "SSH agent socket exists"
else
  skip "SSH agent not detected (expected in non-interactive shells)"
fi

if grep -q "github.com" "$HOME/.ssh/config" 2>/dev/null; then
  pass "SSH config: github.com matchBlock"
else
  fail "SSH config: github.com matchBlock"
fi

if grep -q "gitlab-master.nvidia.com" "$HOME/.ssh/config" 2>/dev/null; then
  pass "SSH config: gitlab-master.nvidia.com matchBlock"
else
  fail "SSH config: gitlab-master.nvidia.com matchBlock"
fi

# --- Git ---
section "Git"
check_git_config() {
  local key="$1" expected="$2" label="$3"
  local val
  val=$(git config "$key" 2>/dev/null || echo "")
  if [ "$val" = "$expected" ]; then
    pass "$label = $expected"
  else
    fail "$label = '$val' (expected '$expected')"
  fi
}

check_git_config "user.name" "Alec Flowers" "git user.name"
check_git_config "user.email" "aflowers@nvidia.com" "git user.email"
check_git_config "commit.gpgsign" "true" "git commit.gpgsign"
check_git_config "gpg.format" "ssh" "git gpg.format"

if git lfs version >/dev/null 2>&1; then
  pass "git-lfs working"
else
  fail "git-lfs working"
fi

# --- Git Remotes ---
section "Git Remotes"
if git ls-remote git@github.com:ai-dynamo/dynamo.git HEAD >/dev/null 2>&1; then
  pass "git ls-remote github.com:ai-dynamo/dynamo.git"
else
  fail "git ls-remote github.com:ai-dynamo/dynamo.git"
fi

if git ls-remote ssh://git@gitlab-master.nvidia.com:12051/dl/ai-dynamo/dynamo-ci.git HEAD >/dev/null 2>&1; then
  pass "git ls-remote gitlab-master.nvidia.com:dynamo-ci.git"
else
  fail "git ls-remote gitlab-master.nvidia.com:dynamo-ci.git"
fi

# --- Auth: gh ---
section "Auth - gh"
if command -v gh >/dev/null 2>&1; then
  if gh auth status 2>&1 | grep -q "Logged in"; then
    pass "gh auth status: logged in"
  else
    fail "gh auth status: not logged in"
  fi
else
  skip "gh not installed"
fi

# --- Auth: glab ---
section "Auth - glab"
if command -v glab >/dev/null 2>&1; then
  if glab auth status 2>&1 | grep -qi "logged in.*gitlab-master.nvidia.com\|gitlab-master.nvidia.com.*logged in"; then
    pass "glab auth status: logged in to gitlab-master.nvidia.com"
  else
    fail "glab auth status: not logged in to gitlab-master.nvidia.com"
  fi
else
  skip "glab not installed"
fi

# --- Auth: ngc ---
section "Auth - ngc"
NGC_CONFIG="$HOME/.ngc/config"
if [ -f "$NGC_CONFIG" ]; then
  if grep -q "org = nvidian" "$NGC_CONFIG" && grep -q "team = dynamo-dev" "$NGC_CONFIG"; then
    pass "ngc config: org=nvidian team=dynamo-dev"
  else
    fail "ngc config: missing org/team"
  fi
else
  fail "ngc config file exists"
fi

if command -v ngc >/dev/null 2>&1; then
  if ngc registry image info nvidian/dynamo-dev/vllm-runtime:hzhou-0225-02 >/dev/null 2>&1; then
    pass "ngc registry image info: accessible"
  else
    fail "ngc registry image info: not accessible"
  fi
else
  skip "ngc not installed"
fi

# --- Auth: docker ---
section "Auth - docker"
DOCKER_CONFIG="$HOME/.docker/config.json"
if [ -f "$DOCKER_CONFIG" ] && grep -q "nvcr.io" "$DOCKER_CONFIG"; then
  pass "docker config: nvcr.io credentials present"
else
  fail "docker config: nvcr.io credentials missing"
fi

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  if docker manifest inspect nvcr.io/nvidian/dynamo-dev/vllm-runtime:hzhou-0225-02 >/dev/null 2>&1; then
    pass "docker manifest inspect nvcr.io image: accessible"
  else
    fail "docker manifest inspect nvcr.io image: not accessible"
  fi
else
  skip "docker not available or daemon not running"
fi

# --- Env Vars ---
section "Env Vars"
for var in GITLAB_TOKEN NGC_CLI_API_KEY HF_TOKEN GH_TOKEN; do
  if [ -n "${!var:-}" ]; then
    pass "$var is set"
  else
    fail "$var is set"
  fi
done

# --- Full Profile Tools (skip if not full) ---
section "Full Profile Tools"
for cmd in aws az kubectl k9s nvsec; do
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd on PATH"
  else
    skip "$cmd not installed (full profile only)"
  fi
done

# --- Tmux ---
section "Tmux"
if [ -f "$HOME/.config/tmux/tmux.conf" ] || [ -f "$HOME/.tmux.conf" ]; then
  pass "tmux config exists"
else
  fail "tmux config exists"
fi

if command -v tmux >/dev/null 2>&1; then
  pass "tmux on PATH"
else
  fail "tmux on PATH"
fi

# --- PATH ---
section "PATH"
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
  pass "~/.local/bin on PATH"
else
  fail "~/.local/bin on PATH"
fi

if [ -L "$HOME/.local/bin/ngc" ] || [ -x "$HOME/.local/bin/ngc" ]; then
  pass "ngc symlink exists in ~/.local/bin"
else
  fail "ngc symlink exists in ~/.local/bin"
fi

# --- Summary ---
printf "\n${BLUE}=== Summary ===${NC}\n"
printf "  ${GREEN}PASS: %d${NC}  ${RED}FAIL: %d${NC}  ${YELLOW}SKIP: %d${NC}\n" "$PASS" "$FAIL" "$SKIP"

if [ "$FAIL" -gt 0 ]; then
  printf "\n${RED}Some tests failed.${NC}\n"
  exit 1
else
  printf "\n${GREEN}All tests passed!${NC}\n"
  exit 0
fi
