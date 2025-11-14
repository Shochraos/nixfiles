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

    plasma-manager = {
          url = "github:nix-community/plasma-manager";
          inputs.nixpkgs.follows = "nixpkgs";
          inputs.home-manager.follows = "home-manager";
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

  outputs = { self, nixpkgs, home-manager, plasma-manager, zen-browser, millennium, ... }@inputs:
  {
    nixosConfigurations =
      let
        makeSystem = name: nixpkgs.lib.nixosSystem
        {
          specialArgs =
          {
          inherit inputs;
          systemName = name;
          userName = "shochraos";
          isAzazel = name == "Azazel";
          isBelphegor = name == "Belphegor";
          };
          modules =
          [
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager =
              {
                extraSpecialArgs =
                {
                systemName = name;
                userName = "shochraos";
                isAzazel = name == "Azazel";
                isBelphegor = name == "Belphegor";
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                users.shochraos =
                {
                  imports =
                  [
                    ./home/home.nix
                    zen-browser.homeModules.beta
                    plasma-manager.homeModules.plasma-manager
                  ];
                };
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
