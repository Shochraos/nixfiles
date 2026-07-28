{
  den.aspects.hdr.provides.to-users.homeManager =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hdrOutputs = builtins.attrNames (lib.filterAttrs (_: output: output.hdr) osConfig.host.outputs);
      hdrOutput =
        if builtins.length hdrOutputs == 1 then
          builtins.head hdrOutputs
        else
          throw "hdr aspect: expected exactly one host.outputs entry with hdr = true, got ${toString (builtins.length hdrOutputs)}";

      hdr-set = pkgs.writeShellApplication {
        name = "hdr-set";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
        ];
        text = ''
          out="$HOME/.config/hypr/dms/outputs.lua"
          line='hl.monitor({ output = "${hdrOutput}", cm = "hdr", min_luminance = 0, max_luminance = 750, max_avg_luminance = 400 })'

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
