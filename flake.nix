{
  description = "NixOS configurations for persephone and hercules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # Declarative Flatpak installs (the OrcaSlicer Flatpak, declared in home.nix).
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs =
    inputs@{
      nixpkgs,
      nixos-hardware,
      home-manager,
      plasma-manager,
      nix-flatpak,
      ...
    }:
    let
      commonModules = [
        ./common.nix
        home-manager.nixosModules.home-manager
        {
          # OrcaSlicer: from-source v2.4.0-beta build that works on these
          # machines (see pkgs/orca-slicer.nix). Applied as an overlay so it
          # reaches home-manager via useGlobalPkgs below.
          nixpkgs.overlays = [ (import ./pkgs/orca-slicer.nix) ];

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Move aside any pre-existing file/dir that a generation wants to own
          # (e.g. VSCodium's mutable ~/.vscode-oss/extensions) instead of
          # aborting activation. Without this, switching to an immutable
          # extensions dir silently fails and no home config applies.
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = [
            plasma-manager.homeModules.plasma-manager
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
          home-manager.users.jsm = import ./home.nix;
        }
      ];
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

      nixosConfigurations.persephone = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
          ./hosts/persephone/default.nix
        ];
      };

      nixosConfigurations.hercules = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          ./hosts/hercules/default.nix
        ];
      };
    };
}
