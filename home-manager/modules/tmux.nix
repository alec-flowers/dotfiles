{ config, pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
    escapeTime = 10;
    baseIndex = 1;

    extraConfig = ''
      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded"

      # Nested tmux: if inside an outer tmux, use C-b as prefix instead
      if-shell '[ -n "$TMUX" ]' {
        set -g prefix C-b
        bind C-b send-prefix
      }

      # Split panes with | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vi-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Clipboard — pure OSC 52 (no external tools, works over SSH)
      set -g set-clipboard on

      # Copy mode — vi keys
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      # Mouse: copy to clipboard on drag end, stay in copy mode
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection

      # Status bar
      set -g status-position bottom
      set -g status-style 'bg=green fg=black'
      set -g status-left '#[fg=black,bg=green,bold] #S '
      set -g status-right '#[fg=black,bg=green,bold] %H:%M '
    '';
  };
}
