{
  description = "NixOS configuration for persephone";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-hardware }: {
    nixosConfigurations.persephone = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
        ./configuration.nix
      ];
    };
  };
}
