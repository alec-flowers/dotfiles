function drun() {
  local target_home="${DRUN_HOME:-/root}"
  local hf_home="${HF_HOME:-$HOME/.cache/huggingface}"
  local cmd=(docker run --rm -it --network=host --gpus all \
    -v "$HOME/.claude:${target_home}/.claude" \
    -v "$HOME/.claude.json:${target_home}/.claude.json" \
    -v "$HOME/.local/share/claude:${target_home}/.local/share/claude" \
    -v "$HOME/.local/bin/claude:/usr/local/bin/claude" \
    -v "$HOME/.codex:${target_home}/.codex" \
    -v "${hf_home}:/hf_cache" \
    -e HF_HOME=/hf_cache \
    -e "HF_TOKEN=${HF_TOKEN}" \
    "$@")
  echo "${cmd[@]}"
  "${cmd[@]}"
}
