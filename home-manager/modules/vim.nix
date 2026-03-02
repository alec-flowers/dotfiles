{ config, pkgs, lib, ... }:

{
  programs.vim = {
    enable = true;

    extraConfig = ''
      set number
      syntax on
      set hlsearch
      set incsearch
      set tabstop=4
      set shiftwidth=4
      set expandtab
      set autoindent
      set ruler
      set wildmenu
    '';
  };
}
