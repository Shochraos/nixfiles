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
        DXVK_NVAPI_DRS_SETTINGS = "ngx_dlss_sr_override=on,ngx_dlss_sr_override_render_preset_selection=render_preset_l,ngx_dlss_rr_override=on,ngx_dlss_rr_override_render_preset_selection=render_preset_l";
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
