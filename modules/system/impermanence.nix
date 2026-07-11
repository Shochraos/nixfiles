{
  aspects.nixos.impermanence =
    { inputs, username, ... }:
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
          "/home/${username}"
        ];

        files = [
          "/etc/machine-id"
          "/var/lib/logrotate.status"
          "/etc/passwd"
          "/etc/shadow"
          "/etc/group"
          "/etc/gshadow"
          "/etc/subuid"
          "/etc/subgid"
        ];
      };
    };
}
