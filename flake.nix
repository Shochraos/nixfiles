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

		nurpkgs = {
              url = "github:mio-19/nurpkgs/bba2f2e4f1459ac2c98ff601dbaf1891160fc30a";
              flake = false; # it’s not a flake
        };
    };

    outputs = { self, nixpkgs, home-manager, zen-browser, millennium, nurpkgs, ... }@inputs:
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

          # Jellyfin-Media-Player overlay to provide qt6 dependencies
          {
            nixpkgs.overlays = [
              (final: prev: {
                jellyfin-media-player =
                  final.callPackage "${nurpkgs}/pkgs/jellyfin-media-player" {
                    qtbase = final.qt6.qtbase;
                    qt5compat = final.qt6.qt5compat;
                    qtdeclarative = final.qt6.qtdeclarative;
                    wrapQtAppsHook = final.qt6.wrapQtAppsHook;
                    qtpositioning   = final.qt6.qtpositioning;
                    qtwayland = final.qt6.qtwayland;
                    qtwebchannel = final.qt6.qtwebchannel;
                    qtwebengine = final.qt6.qtwebengine;
                  };
              })
            ];
          }

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
