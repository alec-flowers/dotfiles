# pull - fetch a file from your Mac via scp
# Usage: drag file from Finder into terminal, then: pull /Users/aflowers/Downloads/file.png
# Auto-detects Mac IP from the active SSH connection.
# Handles macOS unicode narrow no-break spaces in filenames (e.g., screenshots).
pull() {
  local mac_ip=$(who | grep "^$(whoami)" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [[ -z "$mac_ip" ]]; then
    echo "Could not detect Mac IP. Are you SSH'd in?"
    return 1
  fi
  local remote_path="$*"
  local filename=$(basename "$remote_path")

  # Replace regular spaces with ? glob to match unicode no-break spaces in macOS filenames
  local glob_path="${remote_path// /?}"
  local resolved=$(ssh "aflowers@${mac_ip}" "ls -d ${glob_path} 2>/dev/null | head -1")

  if [[ -z "$resolved" ]]; then
    echo "File not found on Mac: ${remote_path}"
    return 1
  fi

  echo "Pulling ${filename}..."
  ssh "aflowers@${mac_ip}" "cat '${resolved}'" > "${HOME}/${filename}"
  echo "Saved to ~/${filename}"
}
