{ ... }:
{
  programs.plasma =
  {
    kscreenlocker =
    {
      autoLock = true;
      timeout = 5;
      passwordRequired = true;
      passwordRequiredDelay = 5;
    };
        
    session =
    {
      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    };
  };
}