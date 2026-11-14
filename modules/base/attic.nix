{ config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.attic.nixos =
    { config, pkgs, ... }:
    let
      queue = "/nix/var/nix/gcroots/attic-upload";
      pushSecret = "attic/${config.networking.hostName}/push-token";
      enqueue = pkgs.writeShellScript "attic-enqueue" ''
        export PATH=${pkgs.coreutils}/bin
        exec ${pkgs.bash}/bin/bash ${assets.atticEnqueueScript} ${queue} /nix/store
      '';
      upload = pkgs.writeShellScript "attic-upload" ''
        export PATH=${pkgs.coreutils}/bin:${pkgs.attic-client}/bin
        exec ${pkgs.bash}/bin/bash ${assets.atticUploadScript} ${queue} /nix/store
      '';
    in
    {
      environment.systemPackages = [ pkgs.attic-client ];
      users.groups.attic-upload = { };
      users.users.attic-upload = {
        isSystemUser = true;
        group = "attic-upload";
      };

      sops.secrets = {
        "network/home-domain" = { };
        "attic/cache-public-key" = { };
        "attic/pull-token" = { };
        ${pushSecret} = {
          owner = "attic-upload";
        };
      };
      sops.templates = {
        "attic-nix.conf" = {
          mode = "0444";
          content = ''
            extra-substituters = https://attic.${config.sops.placeholder."network/home-domain"}/shared
            extra-trusted-public-keys = ${config.sops.placeholder."attic/cache-public-key"}
          '';
          restartUnits = [ "nix-daemon.service" ];
        };
        "attic-netrc" = {
          mode = "0400";
          content = ''
            machine attic.${config.sops.placeholder."network/home-domain"} password ${
              config.sops.placeholder."attic/pull-token"
            }
          '';
          restartUnits = [ "nix-daemon.service" ];
        };
        "attic-client.toml" = {
          owner = "attic-upload";
          mode = "0400";
          content = ''
            [servers.homelab]
            endpoint = "https://attic.${config.sops.placeholder."network/home-domain"}"
            token-file = "${config.sops.secrets.${pushSecret}.path}"
          '';
        };
      };

      nix.settings = {
        post-build-hook = toString enqueue;
        netrc-file = config.sops.templates."attic-netrc".path;
      };
      nix.extraOptions = ''
        !include ${config.sops.templates."attic-nix.conf".path}
      '';

      systemd.tmpfiles.rules = [
        "d ${queue} 0750 attic-upload attic-upload - -"
        "d /run/attic-uploader/attic 0755 root root - -"
        "L+ /run/attic-uploader/attic/config.toml - - - - ${config.sops.templates."attic-client.toml".path}"
      ];
      systemd.services.nix-daemon = {
        wants = [ "systemd-tmpfiles-setup.service" ];
        after = [ "systemd-tmpfiles-setup.service" ];
      };
      systemd.services.attic-upload = {
        description = "Upload queued Nix build outputs to Attic";
        after = [
          "network-online.target"
          "sops-nix.service"
        ];
        wants = [ "network-online.target" ];
        environment.XDG_CONFIG_HOME = "/run/attic-uploader";
        serviceConfig = {
          Type = "oneshot";
          User = "attic-upload";
          Group = "attic-upload";
          ExecStart = upload;
        };
      };
      systemd.timers.attic-upload = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitInactiveSec = "5min";
          Unit = "attic-upload.service";
        };
      };
    };
}
