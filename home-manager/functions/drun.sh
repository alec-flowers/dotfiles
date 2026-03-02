function drun() {
  docker run --rm -it --network=host --gpus all \
    -v "$HOME/.claude:/root/.claude" \
    -v "$HOME/.local/share/claude:/root/.local/share/claude" \
    -v "$HOME/.local/bin/claude:/root/.local/bin/claude" \
    -v "$HOME/.codex:/root/.codex" \
    -e "PATH=/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    "$@"
}
