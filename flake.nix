{
  description = "Dendritic NixOS Flake";

  inputs = {
    ### Repositories and private Inputs ###
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    nixfiles-private = {
      url = "git+ssh://git@git.freunds.me:2222/Shochraos/nixfiles-private.git";
      flake = false;
    };

    ### Nix Utilities
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-your-shell = {
      url = "github:MercuryTechnologies/nix-your-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    ### Boot ###
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ### DMS and Desktop ###
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };


    ### Miscellaneous ###
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ### Gaming ###
    millennium = {
      url = "github:SteamClientHomebrew/Millennium/?dir=packages/nix";
    };

    nix-proton-cachyos = {
      url = "github:Shochraos/nix-proton-cachyos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-dw-proton = {
      url = "github:shochraos/nix-dw-proton";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [ (import-tree ./modules) ];

        options.aspects = lib.mkOption {
          type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
          default = { };
        };

        config.systems = [ "x86_64-linux" ];
      }
    );
}
