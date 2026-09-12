{
  den.aspects.mail = {
    provides.to-users.homeManager =
      { pkgs, lib, ... }:
      let
        tutanotaDisableUpdateCheck = pkgs.writeShellApplication {
          name = "tutanota-disable-update-check";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            conf_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/tutanota-desktop"
            conf="$conf_dir/conf.json"
            mkdir -p "$conf_dir"
            if [ ! -e "$conf" ]; then
                printf '{\n  "enableAutoUpdate": false\n}\n' > "$conf"
                exit 0
            fi
            current="$(jq -r '.enableAutoUpdate' "$conf" 2>/dev/null || true)"
            if [ "$current" = "false" ]; then
                exit 0
            fi
            tmp="$(mktemp "$conf_dir/.conf.json.XXXXXX")"
            if jq '.enableAutoUpdate = false' "$conf" > "$tmp" 2>/dev/null; then
                mv "$tmp" "$conf"
            else
                rm -f "$tmp"
                echo "tutanota-disable-update-check: could not parse $conf, leaving it unchanged" >&2
            fi
          '';
        };
      in
      {
        home.packages = [ pkgs.tutanota-desktop ];
        home.activation.tutanotaDisableUpdateCheck = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${lib.getExe tutanotaDisableUpdateCheck}
        '';
      };
  };
}
