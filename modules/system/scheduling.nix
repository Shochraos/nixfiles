let
  ananicyBuildFixOverlay = _final: prev: {
    ananicy-cpp = prev.ananicy-cpp.overrideAttrs {
      env.CXXFLAGS = "-include cstdint -include cstring";
    };
  };
in
{
  den.aspects.scheduling.nixos =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ ananicyBuildFixOverlay ];

      services.scx = {
        enable = true;
        scheduler = "scx_lavd";
      };

      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
        settings = {
          cgroups = false;
        };
      };
    };
}
