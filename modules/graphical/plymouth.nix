{ inputs, ... }:
{
  den.aspects.plymouth.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acid = import (inputs.acid-boot + "/theme.nix") {
        inherit pkgs;
        palette = "cool-gray";
        columns = 90;
        showLog = true;
        animations = false;
        promptFontName = config.stylix.fonts.monospace.name;
        logFontName = config.stylix.fonts.monospace.name;
      };
    in
    {
      options.boot.plymouth.themePackages = lib.mkOption {
        apply = map (
          theme:
          if lib.hasPrefix "plymouth-theme-acid-nix-" (theme.name or "") then
            theme.overrideAttrs (old: {
              buildCommand = old.buildCommand + ''
                chmod u+w "$out/share/plymouth/themes/acid-nix/acid-nix.script"
                substituteInPlace "$out/share/plymouth/themes/acid-nix/acid-nix.script" \
                  --replace-fail 'log.sprites[i].SetPosition(log.x,' \
                    'log.sprites[i].SetPosition(Math.Int((screen.w - log.image.GetWidth()) / 2),'
                cat >> "$out/share/plymouth/themes/acid-nix/acid-nix.script" <<'EOF'

                fun center_displays_callback() {
                  for (display = 0; Window.GetWidth(display); display++) {
                    Window.SetX(display, Math.Int((screen.w - Window.GetWidth(display)) / 2));
                    Window.SetY(display, Math.Int((screen.h - Window.GetHeight(display)) / 2));
                  }
                  if (anim.enabled)
                    refresh_callback();
                }
                center_displays_callback();
                Plymouth.SetRefreshFunction(center_displays_callback);
                EOF
              '';
            })
          else
            theme
        );
      };

      config = {
        boot.kernelParams = [ "quiet" ];
        boot.consoleLogLevel = 3;

        boot.plymouth = {
          enable = true;
          package = acid.plymouth;
          theme = "acid-nix";
          themePackages = [ acid.theme ];
          font = "${config.stylix.fonts.monospace.package}/share/fonts/opentype/NerdFonts/Overpass/OverpassMNerdFontMono-Regular.otf";
          extraConfig = "DeviceScale=1";
        };

        systemd.services.plymouth-quit.serviceConfig.ExecStart = [
          ""
          "-${config.boot.plymouth.package}/bin/plymouth quit --retain-splash"
        ];
      };
    };
}
