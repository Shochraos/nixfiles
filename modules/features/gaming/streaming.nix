{ lib, ... }:
let
  streamingGeometry =
    display:
    let
      parts = lib.splitString "@" display.mode;
      dims = lib.splitString "x" (builtins.head parts);
    in
    if builtins.length parts != 2 || builtins.length dims != 2 then
      throw "streaming: mode `${display.mode}' must be WIDTHxHEIGHT@REFRESH, e.g. 2560x1440@120"
    else
      {
        width = builtins.elemAt dims 0;
        height = builtins.elemAt dims 1;
        refresh = builtins.elemAt parts 1;
      };
in
{
  den.aspects.gaming.provides.to-users.homeManager =
    {
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (osConfig.host) streaming;

      displays = streaming.displays;

      mkWrappers =
        name: entry:
        let
          inherit (streamingGeometry entry) width height refresh;

          output = entry.output;
          mode = entry.mode;
          geometry = lib.optionalString (entry.scale != null) ", scale = ${entry.scale}";

          displayCmd = pkgs.writeShellApplication {
            name = "${name}-display";
            runtimeInputs = with pkgs; [
              coreutils
              gnugrep
              jq
            ];
            text = ''
              current_mode() {
                hyprctl monitors -j 2>/dev/null |
                  jq -r --arg o "${output}" '.[] | select(.name == $o) | "\(.width)x\(.height)@\(.refreshRate | floor)"'
              }

              our_monitor_id() {
                hyprctl monitors -j 2>/dev/null | jq -r --arg o "${output}" '.[] | select(.name == $o) | .id'
              }

              misplaced_gamescope() {
                local launched_pid our_monitor
                launched_pid="$(cat "$1" 2>/dev/null || true)"
                [ -n "$launched_pid" ] || return 0
                our_monitor="$(our_monitor_id)"
                [ -n "$our_monitor" ] || return 0
                hyprctl clients -j 2>/dev/null |
                  jq -r --argjson launched_pid "$launched_pid" --argjson our_monitor "$our_monitor" '
                    .[]
                    | select(.pid == $launched_pid and .monitor != $our_monitor)
                    | .address'
              }

              case "''${1:-}" in
                present)
                  hyprctl monitors -j 2>/dev/null | jq -r '.[].name' | grep -qxF "${output}"
                  ;;
                focus)
                  hyprctl eval 'hl.dispatch(hl.dsp.focus({ monitor = "${output}" }))' >/dev/null 2>&1 || true
                  ;;
                snapshot)
                  hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' > "$2/focus-addr" || true
                  hyprctl monitors -j 2>/dev/null | jq -r '[.[] | select(.focused)][0].name // empty' > "$2/focus-mon" || true
                  ;;
                place)
                  while read -r address; do
                    [ -n "$address" ] || continue
                    hyprctl eval "hl.dispatch(hl.dsp.window.move({ monitor = '${output}', window = 'address:''${address}' }))" >/dev/null 2>&1 || true
                  done < <(misplaced_gamescope "$2/gamescope.pid")
                  ;;
                restore)
                  address="$(cat "$2/focus-addr" 2>/dev/null || true)"
                  monitor="$(cat "$2/focus-mon" 2>/dev/null || true)"
                  if [ -n "$address" ] &&
                    hyprctl clients -j 2>/dev/null | jq -e --arg a "$address" 'any(.[]; .address == $a)' >/dev/null 2>&1; then
                    hyprctl eval "hl.dispatch(hl.dsp.focus({ window = 'address:''${address}' }))" >/dev/null 2>&1 || true
                  elif [ -n "$monitor" ] &&
                    hyprctl monitors -j 2>/dev/null | jq -e --arg m "$monitor" 'any(.[]; .name == $m)' >/dev/null 2>&1; then
                    hyprctl eval "hl.dispatch(hl.dsp.focus({ monitor = \"''${monitor}\" }))" >/dev/null 2>&1 || true
                  fi
                  ;; 
                ensure)
                  if [ "$(current_mode)" != "${mode}" ]; then
                    hyprctl eval 'hl.monitor({ output = "${output}", mode = "${mode}"${geometry} })' >/dev/null 2>&1 || true
                  fi
                  ;;
                *)
                  echo "usage: ${name}-display present|focus|snapshot|place|restore|ensure" >&2
                  exit 1
                  ;;
              esac
            '';
          };

          recorder = pkgs.writeShellApplication {
            name = "${name}-record";
            text = ''
              rcfile="$1"
              shift
              rc=0
              "$@" || rc=$?
              printf '%s' "$rc" > "$rcfile"
            '';
          };

          wrapper = pkgs.writeShellApplication {
            name = "${name}";
            runtimeInputs = [
              displayCmd
              recorder
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gamescope
              pkgs.jq
              pkgs.util-linux
            ];
            text = ''
              poll="''${STREAM_POLL_INTERVAL:-1}"
              grace="''${STREAM_GRACE:-5}"
              handoff="''${STREAM_HANDOFF:-30}"
              gamescope_cmd="''${STREAM_GAMESCOPE:-gamescope}"

              launch_ld="''${LD_LIBRARY_PATH-}"
              unset LD_LIBRARY_PATH

              lock="''${XDG_RUNTIME_DIR:-/tmp}/streaming-display.lock"
              exec 9>"$lock"
              if ! flock -n 9; then
                echo "${name}: another streaming display is already running — check 'hyprctl monitors' (lock $lock)" >&2
                exit 1
              fi

              state="$(mktemp -d)"
              before="$state/before"
              targets="$state/targets"
              now="$state/now"
              rcfile="$state/rc"
              gspid="$state/gamescope.pid"
              frozen=0
              absent_since=""
              empty_since=""

              classes() { hyprctl clients -j 2>/dev/null | jq -r '.[].class // empty' | sort -u; }

              trap 'exit 130' INT TERM
              trap 'kill "$(cat "$gspid" 2>/dev/null || true)" 2>/dev/null || true; ${name}-display restore "$state" || true; rm -rf "$state" || true' EXIT

              if ! ${name}-display present; then
                echo "${name}: the ${output} display is missing — it is created at compositor start by the hyprland aspect; run 'hyprctl reload' to recreate it" >&2
                exit 1
              fi

              ${name}-display snapshot "$state"
              ${name}-display focus
              classes > "$before"
              : > "$targets"

              ( if [ -n "$launch_ld" ]; then export LD_LIBRARY_PATH="$launch_ld"; fi
                MANGOHUD=0 PROTON_ENABLE_WAYLAND=0 "$gamescope_cmd" \
                  -w ${width} -h ${height} -W ${width} -H ${height} -r ${refresh} \
                  --keep-alive --mangoapp -- \
                  "${name}-record" "$rcfile" "$@" &
                gs=$!
                printf '%s' "$gs" > "$gspid"
                gs_rc=0
                wait "$gs" || gs_rc=$?
                if [ ! -e "$rcfile" ]; then
                  printf '%s' "$gs_rc" > "$rcfile"
                fi ) 9>&- &
              child=$!

              while :; do
                ${name}-display ensure
                ${name}-display place "$state"
                classes > "$now" || true

                if [ "$frozen" -eq 0 ]; then
                  comm -13 "$before" "$now" >> "$targets" 2>/dev/null || true
                  sort -u -o "$targets" "$targets"
                  if [ -s "$targets" ] && [ -e "$rcfile" ]; then
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
                elif [ -e "$rcfile" ]; then
                  if [ -z "$empty_since" ]; then
                    empty_since="$SECONDS"
                  elif [ "$((SECONDS - empty_since))" -ge "$handoff" ]; then
                    break
                  fi
                fi

                sleep "$poll"
              done

              kill "$(cat "$gspid" 2>/dev/null || true)" 2>/dev/null || true
              wait "$child" 2>/dev/null || true
              exit "$(cat "$rcfile" 2>/dev/null || echo 0)"
            '';
          };
        in
        [
          displayCmd
          wrapper
        ];

      packages = lib.concatLists (lib.mapAttrsToList mkWrappers displays);
    in
    {
      home.packages = packages;
    };
}
