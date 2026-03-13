{
  description = "Dendritic NixOS Flake";

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
  
      plasma-manager = 
      {
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
        url = "github:SteamClientHomebrew/Millennium?dir=packages/nix"; 
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };

  outputs = { self, nixpkgs, home-manager, plasma-manager, millennium, zen-browser, ... }@inputs: 
  let
    system = "x86_64-linux";
    username = "shochraos";
  in 
  {
    nixosConfigurations = 
    let 
      makeSystem = name: nixpkgs.lib.nixosSystem
      {
        inherit system;
        specialArgs = { inherit inputs username; systemname = name;}; 
        modules = 
        [
          home-manager.nixosModules.home-manager
          ./hosts/${name}
        ];
    };
    in
    {
      Azazel = makeSystem "Azazel";
      Belphegor = makeSystem "Belphegor";
    };
  };
}