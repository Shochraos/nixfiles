{ config, pkgs, ... }: {

  # User
  users.users.moritz = {
    isNormalUser = true;
    description = "Moritz Freund";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];
    packages = with pkgs; [];
  };
}