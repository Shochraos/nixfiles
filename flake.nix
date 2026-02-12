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
    username = "shochraos"; # Zentral definiert
  in {
    nixosConfigurations.Azazel = nixpkgs.lib.nixosSystem {
      inherit system;
      # Hier geben wir Variablen an die Module weiter
      specialArgs = { inherit inputs username; }; 
      
      modules = [
        # Wichtig: Home-Manager als NixOS Modul laden
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Optional: Damit HM-Configs bei 'nixos-rebuild switch' mitgeändert werden
          home-manager.backupFileExtension = "backup";
        }

        # Der Einstiegspunkt für den Host
        ./hosts/azazel.nix
      ];
    };
  };
}