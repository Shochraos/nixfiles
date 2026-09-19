{
  den.aspects.backup =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        {
          sops.secrets = {
            "backup/storagebox-host".owner = user.name;
            "backup/storagebox-user".owner = user.name;
            "backup/storagebox-ssh-key".owner = user.name;
            "backup/storagebox-passphrase".owner = user.name;
          };

          sops.templates."backup-storagebox-ssh" = {
            owner = user.name;
            content = ''
              Host storagebox
                HostName ${config.sops.placeholder."backup/storagebox-host"}
                User ${config.sops.placeholder."backup/storagebox-user"}
                Port 23
                IdentityFile ${config.sops.secrets."backup/storagebox-ssh-key".path}
                IdentitiesOnly yes
                StrictHostKeyChecking accept-new
            '';
          };

          services.borgbackup.jobs.backup = {
            repo = config.host.backup.repo;
            paths = config.host.backup.paths;
            exclude = config.host.backup.excludes;
            encryption = {
              mode = "repokey";
              passCommand = "cat ${config.sops.secrets."backup/storagebox-passphrase".path}";
            };
            compression = "auto,zstd";
            startAt = "*-*-* 03:30:00";
            persistentTimer = true;
            inhibitsSleep = true;
            prune.keep = {
              daily = 7;
              weekly = 4;
              monthly = 6;
            };
            environment = {
              BORG_REMOTE_PATH = "borg-1.4";
              BORG_RSH = "ssh -F ${config.sops.templates."backup-storagebox-ssh".path}";
            };
          };
        };

      provides.to-users.homeManager =
        {
          lib,
          osConfig,
          pkgs,
          ...
        }:
        let
          archivedRoots = lib.concatMapStringsSep " " (
            p: lib.escapeShellArg (lib.removePrefix "/" p)
          ) osConfig.host.backup.paths;

          cli = pkgs.writeShellApplication {
            name = "backup";
            runtimeInputs = with pkgs; [
              coreutils
              gawk
              gnugrep
            ];
            text = ''
              verb="''${1:-}"
              shift || true

              runtime="''${XDG_RUNTIME_DIR:-/tmp}"
              root="$runtime/borg"
              roots=(${archivedRoots})

              usage() {
                echo "usage: backup mount [ARCHIVE]" >&2
                echo "       backup unmount" >&2
              }

              mounted_targets() {
                findmnt -n -o SOURCE,TARGET --raw 2>/dev/null |
                  awk -v p="$root/" '$1 == "borgfs" && index($2, p) == 1 { print $2 }'
              }

              case "$verb" in
                mount)
                  archive="''${1:-}"
                  if [ -z "$archive" ]; then
                    archive="$(borg list --short --last 1)"
                  fi
                  if [ -z "$archive" ]; then
                    echo "backup: no archive in ''${BORG_REPO:-the repository}" >&2
                    exit 1
                  fi
                  target="$root/$archive"
                  if mounted_targets | grep -qxF "$target"; then
                    echo "$target"
                    exit 0
                  fi
                  mkdir -p "$target"
                  borg mount "::$archive" "$target"
                  echo "$target"
                  for p in "''${roots[@]}"; do
                    if [ -e "$target/$p" ]; then
                      ls -l "$target/$p"
                    fi
                  done
                  ;;
                unmount)
                  status=0
                  count=0
                  while read -r target; do
                    count=$((count + 1))
                    if borg umount "$target"; then
                      rmdir "$target" 2>/dev/null || true
                      echo "unmounted $target"
                    else
                      echo "backup: $target is busy; close what is using it, or force it with: fusermount3 -u -z $target" >&2
                      status=1
                    fi
                  done < <(mounted_targets)
                  if [ "$count" -eq 0 ]; then
                    echo "backup: nothing mounted"
                  fi
                  rmdir "$root" 2>/dev/null || true
                  exit "$status"
                  ;;
                *)
                  usage
                  exit 1
                  ;;
              esac
            '';
          };
        in
        {
          home.packages = [
            pkgs.borgbackup
            cli
          ];

          home.sessionVariables = {
            BORG_REPO = osConfig.host.backup.repo;
            BORG_REMOTE_PATH = "borg-1.4";
            BORG_RSH = "ssh -F ${osConfig.sops.templates."backup-storagebox-ssh".path}";
            BORG_PASSCOMMAND = "cat ${osConfig.sops.secrets."backup/storagebox-passphrase".path}";
          };
        };
    };
}
