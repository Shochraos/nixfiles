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
        package = pkgs.millennium-steam.override {
          extraArgs = "-pipewire";
        };
        extraCompatPackages = [
          proton-cachyos-v3
          dw-proton
        ];
        remotePlay.openFirewall = true;
      };
      programs.gamescope = {
        enable = true;
        capSysNice = false;
      };
    };

  den.aspects.gaming.provides.to-users.nixos =
    {
      config,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      vrcompositorLauncher = "${
        config.users.users.${user.name}.home
      }/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher";
    in
    {
      security.pam.loginLimits = [
        {
          domain = user.name;
          item = "rtprio";
          type = "-";
          value = 95;
        }
      ];

      systemd.services.steamvr-cap-sys-nice = {
        description = "Give SteamVR's vrcompositor-launcher the cap_sys_nice its setup checks for";
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          if [ -e ${lib.escapeShellArg vrcompositorLauncher} ]; then
            ${lib.getExe' pkgs.libcap "setcap"} cap_sys_nice=p ${lib.escapeShellArg vrcompositorLauncher}
          fi
        '';
      };
    };

  den.aspects.gaming.provides.to-users.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      proton-cachyos-v3 =
        inputs.proton-cachyos-nix.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos-v3;
      dw-proton = inputs.dw-proton-nix.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton;
      libGL64 = config.lib.file.mkOutOfStoreSymlink "/run/opengl-driver/lib/libGL.so.1";
      libGL32 = config.lib.file.mkOutOfStoreSymlink "/run/opengl-driver-32/lib/libGL.so.1";
      drsSettings = lib.concatStringsSep "," [
        "ngx_dlss_sr_override=on"
        "ngx_dlss_sr_override_render_preset_selection=render_preset_m"
        "ngx_dlss_rr_override=on"
        "ngx_dlss_rr_override_render_preset_selection=render_preset_f"
      ];

      steamvrFacetRenderer = pkgs.writeShellApplication {
        name = "steamvr-facet-renderer";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          settings="${config.home.homeDirectory}/.local/share/Steam/config/steamvr.vrsettings"

          if [ ! -f "$settings" ]; then
            exit 0
          fi

          if ! current="$(jq -r '.steamvr.useFacetRenderer // false' "$settings" 2>/dev/null)"; then
            echo "steamvr-facet-renderer: $settings is not valid JSON, leaving it untouched" >&2
            exit 0
          fi

          if [ "$current" = "true" ]; then
            exit 0
          fi

          if ! merged="$(jq '.steamvr = ((.steamvr // {}) + {useFacetRenderer: true})' "$settings" 2>/dev/null)"; then
            echo "steamvr-facet-renderer: could not merge into $settings, leaving it untouched" >&2
            exit 0
          fi

          merged_file="$(mktemp "''${settings}.XXXXXX")"
          printf '%s\n' "$merged" > "$merged_file"
          chmod --reference="$settings" "$merged_file"
          mv "$merged_file" "$settings"
        '';
      };
    in
    {
      home.activation.steamvrFacetRenderer = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.getExe steamvrFacetRenderer
      );

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

      home.file = {
        ".local/share/Steam/ubuntu12_64/libGL.so.1" = {
          source = libGL64;
          force = true;
        };
        ".local/share/Steam/ubuntu12_32/libGL.so.1" = {
          source = libGL32;
          force = true;
        };
      };

      xdg.configFile."openxr/1/active_runtime.json".text = ''
        {
           "file_format_version": "1.0.0",
            "runtime": {
            "VALVE_runtime_is_steamvr": true,
            "library_path": "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrclient.so",
            "name": "SteamVR"
            }
        }
      '';
    };
}
