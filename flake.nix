{
  description = "Dendritic NixOS Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    lanzaboote = {
      #url = "github:nix-community/lanzaboote/v1.0.0";
      url = "github:nix-community/lanzaboote/0403b4b7e8b2612657f0053a4c315e6c43eee9e6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
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

    millennium = {
      #url = "github:SteamClientHomebrew/Millennium/next?dir=packages/nix";
      url = "github:Izumemori/Millennium/fix/nix-build?dir=packages/nix";
    };

    nix-proton-cachyos.url = "github:Shochraos/nix-proton-cachyos";

    nix-dw-proton.url = "github:shochraos/nix-dw-proton";
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
