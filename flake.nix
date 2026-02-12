{
  description = "Dentric NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
  let
    system = "x86_64-linux";
    username = "shochraos";
  in 
  {
    nixosConfigurations.Azazel = nixpkgs.lib.nixosSystem 
    {
      inherit system;
      specialArgs = { inherit inputs username; }; 
      modules = 
      [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
        }

        # Der Einstiegspunkt für den Host
        ./hosts/azazel.nix
      ];
    };
  };
}