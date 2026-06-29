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
          ./vps
          ./vps/hosts/corellian-run.nix
        ];
      };
      nixosConfigurations.endor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {inherit inputs;};

        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./vps
          ./vps/hosts/endor.nix
        ];
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      longhornctl = let
        version = "1.10.2";
        rev = "v${version}";
      in
        pkgs.buildGoModule {
          pname = "longhornctl";
          inherit version;
          src = pkgs.fetchFromGitHub {
            owner = "longhorn";
            repo = "cli";
            inherit rev;
            hash = "sha256-9A3GYiujRscoj1ivzBsCOQcqczgP1JS6u3KodRhgtPw=";
          };
          vendorHash = null;

          # Mirror the upstream Makefile/dapper/build workflow: build both the
          # remote (longhornctl) and local (longhornctl-local) commands with the
          # same flags rather than buildGoModule's defaults.
          subPackages = ["cmd/remote" "cmd/local"];

          env.CGO_ENABLED = 0;

          gcflags = ["all=-l"];

          ldflags = [
            "-X github.com/longhorn/cli/meta.Version=${rev}"
            "-X github.com/longhorn/cli/meta.GitCommit=${rev}"
            "-X github.com/longhorn/cli/meta.BuildDate=1970-01-01T00:00:00Z"
            "-extldflags"
            "-static"
            "-s"
          ];

          # dapper/build emits longhornctl (cmd/remote) and longhornctl-local
          # (cmd/local); buildGoModule installs them under their dir names.
          postInstall = ''
            mv $out/bin/remote $out/bin/longhornctl
            mv $out/bin/local $out/bin/longhornctl-local
          '';

          meta.mainProgram = "longhornctl";
        };
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          talosctl
          # kubernetes-helm
          cilium-cli
          kubectl
          talhelper
          fluxcd
          just
          longhornctl
        ];
        shellHook = "exec zsh";
      };
    });
}
