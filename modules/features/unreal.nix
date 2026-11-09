{
  den.aspects.unreal.provides.to-users.homeManager =
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
    };
}
