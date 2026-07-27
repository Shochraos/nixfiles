{ inputs, ... }:
{
  den.aspects.gaming.nixos =
    { pkgs, ... }:
    let
      proton-cachyos =
        inputs.nix-proton-cachyos.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos;
      dw-proton = inputs.nix-dw-proton.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton;
    in
    {
      boot.kernelModules = [ "ntsync" ];

      nixpkgs.overlays = [ inputs.millennium.overlays.default ];
      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;
        extraCompatPackages = [
          proton-cachyos
          dw-proton
        ];
      };
    };

  den.aspects.gaming.provides.to-users.homeManager =
    { pkgs, ... }:
    let
      proton-cachyos =
        inputs.nix-proton-cachyos.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos;
      dw-proton = inputs.nix-dw-proton.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton;
    in
    {
      home.sessionVariables = {
        PROTON_ENABLE_WAYLAND = "1";
        PROTON_DLSS_UPGRADE = "1";
        PROTON_VKD3D_LOWLATENCY = "1";
        VKD3D_CONFIG = "descriptor_heap";
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${proton-cachyos}/share/steam/compatibilitytools.d:${dw-proton}/share/steam/compatibilitytools.d";
      };

      xdg.autostart = {
        entries = [
          "${pkgs.steam}/share/applications/steam.desktop"
        ];
      };
    };
}
