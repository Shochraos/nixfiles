{ lib, isAzazel, ... }:
{
  programs.plasma =
  {
    powerdevil = lib.mkMerge
    [
      {}
      (lib.mkIf isAzazel
      {
        AC =
        {
          autoSuspend.action = "nothing";
          dimDisplay.enable = false;
          powerButtonAction = "showLogoutScreen";

          turnOffDisplay =
          {
            idleTimeout = 36000;
            idleTimeoutWhenLocked = "immediately";
          };
        };
      })
    ];
  };
}