{
  description = "NixOS configurations for persephone and hercules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap-flake.url = "github:xremap/nix-flake";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, xremap-flake, nixvim, stylix, plasma-manager }:
  let
    homeManagerConfig = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.sharedModules = [
        nixvim.homeModules.nixvim
        plasma-manager.homeModules.plasma-manager
      ];
      home-manager.users.jsm = import ./home.nix;
    };

    commonModules = [
      ./common.nix
      xremap-flake.nixosModules.default
      stylix.nixosModules.stylix
      home-manager.nixosModules.home-manager
      homeManagerConfig
    ];
  in
  {
    nixosConfigurations.persephone = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = commonModules ++ [
        nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
        ./hosts/persephone/default.nix
      ];
    };

    nixosConfigurations.hercules = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = commonModules ++ [
        ./hosts/hercules/default.nix
      ];
    };
  };
}
