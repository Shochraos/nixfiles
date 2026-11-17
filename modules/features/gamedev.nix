{ config, den, ... }:
let
  inherit (config) packageSources;
in
{
  den.aspects.gamedev = {
    includes = [
      (den.batteries.unfree [
        "blender"
        "cuda_cudart"
        "cuda_nvcc"
        "libnvvm"
        "cuda_crt"
        "cccl"
      ])
    ];
    provides.to-users.homeManager = {
      imports = [
        (
          {
            pkgs,
            osConfig,
            ...
          }:
          let
            isNvidia = osConfig.networking.hostName == "Azazel";
            blender = pkgs.blender.override {
              cudaSupport = isNvidia;
              rocmSupport = !isNvidia;
            };
            server = pkgs.callPackage packageSources.blenderLabMcp { };
            startup = pkgs.writeText "blender-mcp-startup.py" ''
              import sys
              import addon_utils
              import bpy

              bpy.context.preferences.use_preferences_save = False
              for entry in tuple(bpy.context.preferences.addons):
                  module_name = entry.module
                  if module_name.startswith("bl_ext.") and module_name.endswith(".mcp"):
                      addon_utils.disable(module_name, default_set=True)
              addon_utils.disable("blender_mcp_addon", default_set=False)
              for name in tuple(sys.modules):
                  if name == "blender_mcp_addon" or name.startswith("blender_mcp_addon."):
                      del sys.modules[name]
              sys.path.insert(0, "${server.addonSource}")
              addon = addon_utils.enable("blender_mcp_addon", default_set=True, persistent=True)
              if addon is None:
                  raise RuntimeError("Could not enable the Blender Lab MCP add-on")
              prefs = bpy.context.preferences.addons["blender_mcp_addon"].preferences
              prefs.host = "127.0.0.1"
              prefs.port = 9876
              if not bpy.app.background:
                  if bpy.app.timers.is_registered(addon._autostart_timer):
                      bpy.app.timers.unregister(addon._autostart_timer)
                  bpy.app.timers.register(addon._autostart_timer, first_interval=1.0, persistent=True)
            '';
            launcher = pkgs.symlinkJoin {
              name = "blender-with-mcp";
              paths = [ blender ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram "$out/bin/blender" \
                  --add-flags "--online-mode --python-exit-code 1 --python ${startup}"
              '';
            };
            bridge = pkgs.symlinkJoin {
              name = "blender-lab-mcp-wrapped";
              paths = [ server ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram "$out/bin/blender-mcp" \
                  --set BLENDER_MCP_HOST 127.0.0.1 \
                  --set BLENDER_MCP_PORT 9876 \
                  --set BLENDER_PATH ${launcher}/bin/blender
              '';
            };
          in
          {
            home.packages = [
              launcher
              bridge
            ];
            xdg.desktopEntries.blender = {
              name = "Blender";
              genericName = "3D modeler";
              exec = "${launcher}/bin/blender %f";
              icon = "blender";
              categories = [
                "Graphics"
                "3DGraphics"
              ];
              mimeType = [ "application/x-blender" ];
            };
          }
        )
        (
          { pkgs, ... }:
          let
            unreal-engine = pkgs.buildFHSEnv {
              name = "unreal-engine";
              targetPkgs =
                p: with p; [
                  alsa-lib
                  at-spi2-core
                  cairo
                  cups
                  curl
                  dbus
                  expat
                  fontconfig
                  freetype
                  glib
                  gtk3
                  icu
                  krb5
                  libdrm
                  libglvnd
                  libpulseaudio
                  libunwind
                  libuuid
                  libx11
                  libxcb
                  libxcomposite
                  libxcursor
                  libxdamage
                  libxext
                  libxfixes
                  libxi
                  libxinerama
                  libxkbcommon
                  libxrandr
                  libxrender
                  libxscrnsaver
                  libxtst
                  lttng-ust
                  nspr
                  nss
                  numactl
                  openssl
                  pango
                  udev
                  vulkan-loader
                  wayland
                  zlib
                ];
              runScript = pkgs.writeShellScript "unreal-engine-launcher" ''
                engine_root="''${UNREAL_ENGINE_ROOT:-''${XDG_DATA_HOME:-$HOME/.local/share}/unreal-engine}"
                editor="$engine_root/Engine/Binaries/Linux/UnrealEditor"
                if [ ! -x "$editor" ]; then
                  printf 'Unreal Engine editor is missing or not executable: %s\nDownload the official Linux binary from Epic Games and extract it to %s, or set UNREAL_ENGINE_ROOT to its extracted directory.\n' "$editor" "$engine_root" >&2
                  exit 1
                fi
                exec "$editor" "$@"
              '';
            };
          in
          {
            home.packages = [ unreal-engine ];

            home.file.".config/Epic/Unreal Engine/Engine/Config/UserGame.ini" = {
              force = true;
              text = ''
                [StartupActions]
                -InsertPack=(PackSource="StarterContent.upack",PackName="StarterContent")
              '';
            };

            xdg.desktopEntries.unreal-engine = {
              name = "Unreal Engine";
              exec = "unreal-engine %f";
              terminal = false;
            };
          }
        )
      ];
    };
  };
}
