{
  aspects.nixos.impermanence =
    {
      inputs,
      username,
      config,
      ...
    }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      environment.persistence."/persist" = {
        enable = true;
        hideMounts = true;

        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd"
          "/var/lib/sbctl"
          "/var/lib/bluetooth"
          "/var/lib/libvirt"
          "/var/lib/AccountsService"
          "/var/lib/cups"
          "/etc/cups"
          "/etc/lact"
          "/etc/NetworkManager/system-connections"
        ]
        ++ config.host.persistence.directories;

        files = [
          "/etc/machine-id"
          "/var/lib/logrotate.status"
          "/etc/passwd"
          "/etc/shadow"
          "/etc/group"
          "/etc/gshadow"
          "/etc/subuid"
          "/etc/subgid"
        ]
        ++ config.host.persistence.files;

        users.${username} = {
          directories = [
            "Desktop"
            "Documents"
            "Downloads"
            "Music"
            "Pictures"
            "Videos"
            "Repositories"
            "Applications"
            "Nextcloud"

            {
              directory = ".ssh";
              mode = "0700";
            }
            ".claude"
            ".electrum"

            ".steam"
            ".local/share/Steam"
            ".cache/nvidia"

            ".config/discord"
            ".config/Vencord"
            ".config/spotify"
            ".config/zen"
            ".config/Nextcloud"
            ".config/feishin"
            ".config/valent"
            ".config/dconf"
            ".config/DankMaterialShell"
            ".config/jellyfin-mpv-shim"
            ".config/faugus-launcher"
            ".config/input-remapper-2"
            ".config/feather"

            ".local/share/fish"
            ".local/share/keyrings"
            ".local/share/zed"
            ".local/share/opencode"
            ".local/share/direnv"
            ".local/share/vdirsyncer"
            ".local/share/calendars"
            ".local/share/DankMaterialShell"

            ".local/state/DankMaterialShell"
          ]
          ++ config.host.persistence.home.directories;

          files = [
            ".claude.json"
            ".aiopylgtv.sqlite"
          ]
          ++ config.host.persistence.home.files;
        };
      };
    };
}
