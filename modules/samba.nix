{ config, pkgs, userName, ... }:
{
  # Samba firewall rules
  networking.firewall.extraCommands = ''iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns'';

  # Install cifs-utils for mounting samba shares
  environment.systemPackages = [ pkgs.cifs-utils ];

  # Mount samba shares
  fileSystems."/mnt/astaroth/appdata" =
  {
    device = "//192.168.178.2/appdata";
    fsType = "cifs";
    options = let
    # this line prevents hanging on network split
    automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.users.users.${userName}.home}/.smb/smb-secrets,uid=1000,gid=100"];
  };

  fileSystems."/mnt/astaroth/backups" =
  {
    device = "//192.168.178.2/backups";
    fsType = "cifs";
    options = let
    # this line prevents hanging on network split
    automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.users.users.${userName}.home}/.smb/smb-secrets,uid=1000,gid=100"];
  };

  fileSystems."/mnt/astaroth/data" =
  {
    device = "//192.168.178.2/data";
    fsType = "cifs";
    options = let
    # this line prevents hanging on network split
    automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.users.users.${userName}.home}/.smb/smb-secrets,uid=1000,gid=100"];
  };
}