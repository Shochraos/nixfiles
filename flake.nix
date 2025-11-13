{
  inputs =
  {
    nixpkgs =
    {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager =
    {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser =
    {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-your-shell =
    {
      url = "github:MercuryTechnologies/nix-your-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    millennium =
    {
      url = "git+https://github.com/SteamClientHomebrew/Millennium";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, millennium, ... }@inputs:
  {
    nixosConfigurations =
      let
        makeSystem = name: nixpkgs.lib.nixosSystem
        {
          specialArgs = { inherit inputs; systemName = name; };
          modules =
          [
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { systemName = name; };
              home-manager.users.shochraos =
              {
                imports =
                [
                  ./home/home.nix
                  zen-browser.homeModules.beta
                ];
              };
            }
          ];
        };
      in
      {
        # Systems
        Azazel = makeSystem "Azazel";
        Belphegor = makeSystem "Belphegor";
      };
    };
  }
