{
  description = "Alec's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      linuxSystem = "x86_64-linux";

      # Helper to build a homeConfiguration
      mkHome = { user, homeDirectory, modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          modules = modules;
          extraSpecialArgs = {
            inherit user homeDirectory;
          };
        };

      # --- Add new users here ---
      users = [
        { name = "aflowers"; home = "/home/aflowers"; }
        { name = "ubuntu";   home = "/home/ubuntu"; }
        { name = "nvidia";   home = "/home/nvidia"; }
        { name = "root";     home = "/root"; }
        { name = "dynamo";   home = "/home/dynamo"; }
      ];

      profiles = {
        core = [ ./home.nix ];
        full = [ ./home.nix ./modules/full.nix ];
      };

      profileNames = builtins.attrNames profiles;

      # Generate "{user}-{profile}" for every user × profile combo
      mkConfigs = builtins.listToAttrs (builtins.concatMap (u:
        map (p: {
          name = "${u.name}-${p}";
          value = mkHome {
            user = u.name;
            homeDirectory = u.home;
            modules = profiles.${p};
          };
        }) profileNames
      ) users);
    in
    {
      homeConfigurations = mkConfigs;

      formatter.${linuxSystem} = nixpkgs.legacyPackages.${linuxSystem}.nixpkgs-fmt;
    };
}
