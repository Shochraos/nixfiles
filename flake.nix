{
  description = "NixOS Configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-your-shell = {
      url = "github:MercuryTechnologies/nix-your-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    millennium.url = "git+https://github.com/SteamClientHomebrew/Millennium";
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, millennium, ... }@inputs:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations =
    {
    ##TODO HIER JEWEILS MODUL FÜR AZAZEL UND BELPHEGOR DIE JEWEILS DAS GLEICHE AUßER DER HOME.NIX IMPORTIEREN, DIE HOME.NIX WIRD JEWEILS UMBENANNT IN AZAZEL.NIX UND BELPHEGOR.NIX UND IMPORTIERT DANN WIEDERUM DIE NÖTIGEN MODULE
      system  = nixpkgs.lib.nixosSystem
      {
        inherit system;
        specialArgs = { inherit inputs system; };

        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shochraos =
            {
              imports =
              [
                ./home/home.nix
                zen-browser.homeModules.beta
              ];
              home.packages =
              [
                inputs.zen-browser.packages.${system}.default
              ];
            };
          }
        ];
      };
    };
  };
}
