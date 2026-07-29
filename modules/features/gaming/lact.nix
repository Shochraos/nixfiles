{ inputs, ... }:
let
  lactBuildFixOverlay = final: prev: {
    inherit (inputs.nixpkgs-small.legacyPackages.${prev.stdenv.hostPlatform.system}) lact;
  };
in
{
  den.aspects.gaming.nixos =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ lactBuildFixOverlay ];
      environment.systemPackages = with pkgs; [ lact ];
      systemd = {
        packages = with pkgs; [ lact ];
        services.lactd.wantedBy = [ "multi-user.target" ];
      };
    };
}
