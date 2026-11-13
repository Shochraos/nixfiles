{ inputs, ... }:
{
  den.aspects.plymouth.nixos =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.acid-boot.nixosModules.default ];

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
        acidBoot = {
          enable = true;
          palette = "doom-red";
          columns = 90;
          showLog = true;
          animations = true;
          entryStyle = "decode";
          promptFontName = config.stylix.fonts.monospace.name;
          logFontName = config.stylix.fonts.monospace.name;
          fontFiles = [
            "${config.stylix.fonts.monospace.package}/share/fonts/opentype/NerdFonts/Overpass/OverpassMNerdFontMono-Regular.otf"
          ];
        };

        boot.kernelParams = [ "quiet" ];
        boot.consoleLogLevel = 3;
      };
    };
}
