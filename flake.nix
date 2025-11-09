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
      in {
      	nixosConfigurations = {
	  azazel  = nixpkgs.lib.nixosSystem {
	    inherit system;
	    specialArgs = { inherit inputs system; };

	    modules = [
	      ./configuration.nix
	      ./hardware-configuration.nix

	      home-manager.nixosModules.home-manager
	      {
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.shochraos = {
				imports = [
					./home/home.nix
					zen-browser.homeModules.beta
					];
				home.packages = [
						inputs.zen-browser.packages.${system}.default
				];
			};
	      }
	    ];
	  };
	};
      };
}
