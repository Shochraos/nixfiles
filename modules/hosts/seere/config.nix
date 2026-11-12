{
  den.aspects.seere.nixos = { config, pkgs, ... }: {
    boot.lanzaboote.measuredBoot.enable = false;
    zramSwap.enable = true;
    systemd.sleep.settings.Sleep = {
      AllowSuspend = false;
      AllowHibernation = false;
      AllowHybridSleep = false;
      AllowSuspendThenHibernate = false;
    };

    networking.nftables.enable = true;
    services.adguardhome.settings.tls.server_name = "dns1.${
      config.sops.placeholder."network/home-domain"
    }";

    system.stateVersion = "26.11";
    boot.kernelPackages = pkgs.linuxPackages;
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    security.sudo.wheelNeedsPassword = false;
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings.AuthenticationMethods = "publickey";
    };
    users.users.shochraos.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3/LOpaM2lZXU9aJnpySqOqK1ucSCTRWgBj8BNY8qg6 shochraos@Azazel"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC71dT73gYzQ5zQz0hAeqC6XccOcBmBxGh9Fk2xztTb6 hermes-gateway"
    ];
  };

  den.aspects.seere.provides.to-users.homeManager = _: {
    home.stateVersion = "26.11";
  };
}
