{ inputs, ... }:
{
  den.aspects.gaming.nixos =
    { pkgs, ... }:
    let
      proton-cachyos-v3 =
        inputs.proton-cachyos-nix.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos-v3;
      dw-proton = inputs.dw-proton-nix.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton;
    in
    {
      boot.kernelModules = [ "ntsync" ];

      nixpkgs.overlays = [ inputs.millennium.overlays.default ];
      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;
        extraCompatPackages = [
          proton-cachyos-v3
          dw-proton
        ];
      };
    };

  den.aspects.gaming.provides.to-users.homeManager =
    { lib, pkgs, ... }:
    let
      proton-cachyos-v3 =
        inputs.proton-cachyos-nix.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos-v3;
      dw-proton = inputs.dw-proton-nix.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton;
      drsSettings = lib.concatStringsSep "," [
        "ngx_dlss_sr_override=on"
        "ngx_dlss_sr_override_render_preset_selection=render_preset_m"
        "ngx_dlss_rr_override=on"
        "ngx_dlss_rr_override_render_preset_selection=render_preset_f"
      ];
    in
    {
      home.sessionVariables = {
        PROTON_ENABLE_WAYLAND = "1";
        PROTON_DLSS_UPGRADE = "1";
        PROTON_VKD3D_LOWLATENCY = "1";
        DXVK_NVAPI_DRS_SETTINGS = drsSettings;
        VKD3D_CONFIG = "descriptor_heap";
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${proton-cachyos-v3}/share/steam/compatibilitytools.d:${dw-proton}/share/steam/compatibilitytools.d";
      };

      xdg.autostart = {
        entries = [
          "${pkgs.steam}/share/applications/steam.desktop"
        ];
      };
    };
}
