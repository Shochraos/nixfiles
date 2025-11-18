{ pkgs, userName, ... }:
{
  # User
  users.users.${userName} =
  {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];
  };
}
