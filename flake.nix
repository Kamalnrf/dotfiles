{
  description = "Kamal's cross-platform Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      mkHome =
        {
          system,
          username,
          homeDirectory,
          modules,
        }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg:
              nixpkgs.lib.getName pkg == "1password-cli";
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/common.nix
            {
              home = {
                inherit username homeDirectory;
              };
            }
          ] ++ modules;
        };
    in
    {
      packages.aarch64-darwin.home-manager = home-manager.packages.aarch64-darwin.default;
      packages.x86_64-linux.home-manager = home-manager.packages.x86_64-linux.default;

      homeConfigurations = {
        kamal = mkHome {
          system = "aarch64-darwin";
          username = "kamal";
          homeDirectory = "/Users/kamal";
          modules = [ ./home/darwin.nix ];
        };

        exedev = mkHome {
          system = "x86_64-linux";
          username = "exedev";
          homeDirectory = "/home/exedev";
          modules = [ ./home/exedev.nix ];
        };
      };
    };
}
