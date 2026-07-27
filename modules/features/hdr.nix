{
  den.aspects.hdr.provides.to-users.homeManager =
    { osConfig, pkgs, ... }:
    let
      hdr-set = pkgs.writeShellApplication {
        name = "hdr-set";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
        ];
        text = ''
          out="$HOME/.config/hypr/dms/outputs.lua"
          line='hl.monitor({ output = "${osConfig.host.hdrOutput}", cm = "hdr", min_luminance = 0, max_luminance = 750, max_avg_luminance = 400 })'

          reload() { hyprctl reload >/dev/null 2>&1 || true; }

          case "''${1:-}" in
            on)
              grep -qxF "$line" "$out" 2>/dev/null || printf '\n%s\n' "$line" >> "$out"
              reload
              ;;
            off)
              if [ -f "$out" ] && grep -qxF "$line" "$out"; then
                grep -vxF "$line" "$out" > "$out.tmp" || true
                mv "$out.tmp" "$out"
                reload
              fi
              ;;
            *)
              echo "usage: hdr-set on|off" >&2
              exit 1
              ;;
          esac
        '';
      };
    in
    {
      home.packages = [
        hdr-set
        (pkgs.writeShellApplication {
          name = "hdr";
          runtimeInputs = [ hdr-set ];
          text = ''
            trap 'hdr-set off' EXIT INT TERM
            hdr-set on
            "$@"
          '';
        })
      ];
    };
}
