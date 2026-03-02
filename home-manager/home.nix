{ config, pkgs, lib, user, homeDirectory, ... }:

{
  home = {
    username = user;
    homeDirectory = homeDirectory;
    stateVersion = "24.05";

    shellAliases = {
      edit-home = "$EDITOR ~/dotfiles/home-manager/home.nix";
      rebuild = "home-manager switch";
      rm = "rm -I";
    };
  };

  imports = [
    ./modules/vim.nix
    ./modules/git.nix
    ./modules/zsh.nix
    ./modules/bash.nix
    ./modules/ssh.nix
    ./modules/tmux.nix
    ./modules/ngc.nix
    ./modules/auth.nix
  ];

  home.packages = with pkgs; [
    git
    curl
    wget
    jq
    ripgrep
    htop
    tmux
    gh
    glab
    git-lfs
    gnupg
    bat
  ];

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  news.display = "silent";

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
}
