{ inputs, ... }:
{
  den.aspects.gaming.nixos =
    { pkgs, ... }:
    let
      proton-cachyos = inputs.nix-proton-cachyos.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos;
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
      proton-cachyos = inputs.nix-proton-cachyos.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos;
      dw-proton = inputs.nix-dw-proton.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton;
    in
    {
      home.packages = [
        (pkgs.writeShellScriptBin "hdr" ''
          set -u
          OUT="$HOME/.config/hypr/dms/outputs.lua"
          LINE='hl.monitor({ output = "HDMI-A-1", cm = "hdr", min_luminance = 0, max_luminance = 750, max_avg_luminance = 400 })'

          hdr_off() {
            if [ -f "$OUT" ] && grep -qxF "$LINE" "$OUT"; then
              grep -vxF "$LINE" "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"
              hyprctl reload >/dev/null 2>&1
            fi
          }
          trap hdr_off EXIT INT TERM

          grep -qxF "$LINE" "$OUT" || printf '\n%s\n' "$LINE" >> "$OUT"
          hyprctl reload >/dev/null 2>&1

          "$@"
        '')
      ];

      home.sessionVariables = {
        PROTON_ENABLE_WAYLAND = "1";
        PROTON_DLSS_UPGRADE = "1";
        PROTON_VKD3D_LOWLATENCY = "1";
        VKD3D_CONFIG = "descriptor_heap";
        STEAM_EXTRA_COMPAT_TOOLS_PATHS =
          "${proton-cachyos}/share/steam/compatibilitytools.d:${dw-proton}/share/steam/compatibilitytools.d";
      };

      xdg.autostart = {
        entries = [
          "${pkgs.steam}/share/applications/steam.desktop"
        ];
      };
    };
}
