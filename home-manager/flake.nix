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

      coreModules = [ ./home.nix ];
      fullModules = [ ./home.nix ./modules/full.nix ];
    in
    {
      homeConfigurations = {
        # Lightweight profiles (core only)
        "local" = mkHome {
          user = "aflowers";
          homeDirectory = "/home/aflowers";
          modules = coreModules;
        };

        "brev-vm" = mkHome {
          user = "ubuntu";
          homeDirectory = "/home/ubuntu";
          modules = coreModules;
        };

        "brev-vm-gpu" = mkHome {
          user = "nvidia";
          homeDirectory = "/home/nvidia";
          modules = coreModules;
        };

        # Full profiles (core + full extras)
        "local-full" = mkHome {
          user = "aflowers";
          homeDirectory = "/home/aflowers";
          modules = fullModules;
        };

        "brev-vm-full" = mkHome {
          user = "ubuntu";
          homeDirectory = "/home/ubuntu";
          modules = fullModules;
        };

        "brev-vm-root" = mkHome {
          user = "root";
          homeDirectory = "/root";
          modules = coreModules;
        };
      };

      formatter.${linuxSystem} = nixpkgs.legacyPackages.${linuxSystem}.nixpkgs-fmt;
    };
}
