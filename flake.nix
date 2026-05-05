{
  description = "Homelab development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    disko,
    sops-nix,
    ...
  }:
    {
      nixosConfigurations.corellian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {inherit inputs;};

        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./vps/configuration.nix
        ];
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          talosctl
          kubernetes-helm
          cilium-cli
          kubectl
        ];
        shellHook = "exec zsh";
      };
    });
}
