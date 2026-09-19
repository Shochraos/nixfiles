{ lib, ... }:
let
  hdrOutputFor =
    outputs:
    let
      hdrOutputs = builtins.attrNames (lib.filterAttrs (_: output: output.hdr) outputs);
    in
    if builtins.length hdrOutputs == 1 then
      builtins.head hdrOutputs
    else
      throw "hdr aspect: expected exactly one host.outputs entry with hdr = true, got ${toString (builtins.length hdrOutputs)}";
in
{
  den.aspects.hdr.provides.to-users.homeManager =
    {
      osConfig,
      pkgs,
      ...
    }:
    let
      hdrOutput = hdrOutputFor osConfig.host.outputs;

      hdr-set = pkgs.writeShellApplication {
        name = "hdr-set";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
        ];
        text = ''
          out="$HOME/.config/hypr/dms/outputs.lua"
          line='hl.monitor({ output = "${hdrOutput}", cm = "hdredid" })'

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
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            jq
            hdr-set
          ];
          text = ''
            poll="''${HDR_POLL_INTERVAL:-1}"
            grace="''${HDR_GRACE:-5}"
            handoff="''${HDR_HANDOFF:-30}"

            launch_ld="''${LD_LIBRARY_PATH-}"
            unset LD_LIBRARY_PATH

            state="$(mktemp -d)"
            before="$state/before"
            targets="$state/targets"
            now="$state/now"
            rcfile="$state/rc"
            frozen=0
            absent_since=""
            empty_since=""

            classes() { hyprctl clients -j 2>/dev/null | jq -r '.[].class // empty' | sort -u; }

            trap 'exit 130' INT TERM
            trap 'hdr-set off; rm -rf "$state"' EXIT

            hdr-set on
            classes > "$before"
            : > "$targets"

            ( if [ -n "$launch_ld" ]; then export LD_LIBRARY_PATH="$launch_ld"; fi
              "$@" || rc=$?; printf '%s' "''${rc:-0}" > "$rcfile" ) &
            child=$!

            while :; do
              classes > "$now" || true

              if [ "$frozen" -eq 0 ]; then
                comm -13 "$before" "$now" >> "$targets" 2>/dev/null || true
                sort -u -o "$targets" "$targets"
                if [ -s "$targets" ] && [ -f "$rcfile" ]; then
                  frozen=1
                fi
              fi

              if [ -s "$targets" ]; then
                if comm -12 "$targets" "$now" 2>/dev/null | grep -q .; then
                  absent_since=""
                elif [ -z "$absent_since" ]; then
                  absent_since="$SECONDS"
                elif [ "$((SECONDS - absent_since))" -ge "$grace" ]; then
                  break
                fi
              elif [ -f "$rcfile" ]; then
                if [ -z "$empty_since" ]; then
                  empty_since="$SECONDS"
                elif [ "$((SECONDS - empty_since))" -ge "$handoff" ]; then
                  break
                fi
              fi

              sleep "$poll"
            done

            wait "$child" 2>/dev/null || true
            exit "$(cat "$rcfile" 2>/dev/null || echo 0)"
          '';
        })
      ];
    };
}
