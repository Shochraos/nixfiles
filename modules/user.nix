{ config, pkgs, ... }: {

  # User
  users.users.shochraos = {
    isNormalUser = true;
    description = "Shochraos";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];
    packages = with pkgs; [];
  };
}
