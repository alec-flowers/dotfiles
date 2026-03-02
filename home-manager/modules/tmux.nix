{ config, pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    keyMode = "vi";
    mouse = true;
    terminal = "screen-256color";
    historyLimit = 50000;
    escapeTime = 10;
    baseIndex = 1;

    extraConfig = ''
      # Reload config
      bind r source-file ~/.tmux.conf \; display "Reloaded"

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

      # Copy mode improvements
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -in -selection clipboard"

      # Status bar
      set -g status-position bottom
      set -g status-style 'bg=green fg=black'
      set -g status-left '#[fg=black,bg=green,bold] #S '
      set -g status-right '#[fg=black,bg=green,bold] %H:%M '
    '';
  };
}
