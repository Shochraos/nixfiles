{
  den.aspects.backup = _: {
    nixos =
      { config, pkgs, ... }:
      let
        borgbackupSphinxOverlay = _final: prev: {
          borgbackup = prev.borgbackup.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + "\n"
              + ''
                test "$(grep -Fc '                except:' src/borg/testsuite/locking.py)" -eq 1
                repositoryContexts=$(grep -Fc '            with self.repository:' src/borg/testsuite/repository.py)
                substituteInPlace src/borg/testsuite/__init__.py \
                  --replace-fail 'platform.set_flags(file.name, stat.UF_NODUMP)' \
                    'platform.set_flags(file.name, stat.UF_NODUMP); has_lchflags = bool(platform.get_flags(file.name, os.stat(file.name)) & stat.UF_NODUMP)'
                substituteInPlace src/borg/testsuite/locking.py \
                  --replace-fail 'import random' $'import errno\nimport random' \
                  --replace-fail '                except:' $'                except BaseException as error:\n                    if isinstance(error, OSError) and error.errno == errno.ESTALE:\n                        continue'
                substituteInPlace src/borg/testsuite/repository.py \
                  --replace-fail $'            with self.repository:\n                # the repo is only locked by a shared read lock, but to replay segments,\n                # we need an exclusive write lock - check if the lock gets upgraded.\n                self.assert_raises(LockFailed, lambda: len(self.repository))\n                upgrade.assert_called_once_with()' $'            # the repo is only locked by a shared read lock, but to replay segments,\n            # we need an exclusive write lock - check if the lock gets upgraded.\n            self.assert_raises(LockFailed, lambda: len(self.repository))\n            upgrade.assert_called_once_with()'
                test "$((repositoryContexts - $(grep -Fc '            with self.repository:' src/borg/testsuite/repository.py)))" -eq 2
              '';
            preCheck =
              (old.preCheck or "")
              + "\n"
              + ''
                borgOriginalTmpDir="$TMPDIR"
                mkdir -p "$TMPDIR/borg-check"
                exec {borgTmpFd}<"$TMPDIR/borg-check"
                export TMPDIR="/proc/$$/fd/$borgTmpFd"
              '';
            postCheck = ''
              export TMPDIR="$borgOriginalTmpDir"
              exec {borgTmpFd}<&-
            ''
            + (old.postCheck or "");
            preInstallSphinx = ''
              rm -rf .sphinx/man/man/_static
            '';
          });
        };
      in
      {
        nixpkgs.overlays = [ borgbackupSphinxOverlay ];

        sops.secrets = {
          "backup/storagebox-host".owner = "shochraos";
          "backup/storagebox-user".owner = "shochraos";
          "backup/storagebox-ssh-key".owner = "shochraos";
          "backup/storagebox-passphrase".owner = "shochraos";
        };

        programs.ssh.knownHosts.storagebox = {
          hostNames = [ "storagebox" ];
          publicKey = config.host.backup.sshHostKey;
        };

        sops.templates."backup-storagebox-ssh" = {
          owner = "root";
          group = config.users.users.shochraos.group;
          mode = "0440";
          content = ''
            Host storagebox
              HostName ${config.sops.placeholder."backup/storagebox-host"}
              User ${config.sops.placeholder."backup/storagebox-user"}
              Port 23
              IdentityFile ${config.sops.secrets."backup/storagebox-ssh-key".path}
              IdentitiesOnly yes
              HostKeyAlias storagebox
              StrictHostKeyChecking yes
          '';
        };

        systemd.services.borgbackup-job-backup.onFailure = [ "borgbackup-notify.service" ];

        systemd.services.borgbackup-notify = {
          description = "Notify the user when the borg backup failed";
          serviceConfig = {
            Type = "oneshot";
            User = "shochraos";
          };
          script = ''
            echo "borgbackup-job-backup failed" >&2
            export XDG_RUNTIME_DIR="/run/user/$(id -u)"
            export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
            if [ -S "$XDG_RUNTIME_DIR/bus" ]; then
              ${pkgs.libnotify}/bin/notify-send -u critical "Borg backup failed" "See journalctl -u borgbackup-job-backup"
            else
              echo "No user session bus is available; backup failure remains in the system journal" >&2
            fi
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
            yearly = 2;
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
        config,
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
            borgbackup
            coreutils
            gawk
            gnugrep
            openssh
            util-linux
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
      lib.mkIf (config.home.username == "shochraos") {
        home.packages = [
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
