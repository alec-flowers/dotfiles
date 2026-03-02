{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    userName = "Alec Flowers";
    userEmail = "aflowers@nvidia.com";

    extraConfig = {
      core = {
        editor = "vim";
      };

      init.defaultBranch = "main";
      pull.rebase = false;
      push.default = "simple";

      # SSH signing
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/gitlab_2026_01.pub";

      # GitLab URL rewrite: use SSH instead of HTTPS
      url = {
        "git@gitlab-master.nvidia.com:" = {
          insteadOf = "https://gitlab-master.nvidia.com/";
        };
      };

      # Credential store for HTTPS fallback
      credential.helper = "store";

      # Git LFS
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*~"
      ".env"
      "node_modules/"
      "__pycache__/"
      "*.pyc"
    ];

    lfs.enable = true;
  };
}
