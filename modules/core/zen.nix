{ inputs, lib, username, ... }:
{
  programs.firefox.enable = false;
  
  home-manager.users.${username} = 
  {
    imports = [ inputs.zen-browser.homeModules.beta ];
    
    programs.zen-browser = 
    {
      enable = true;
      policies = 
      {
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        Cookies = 
        {
          Behavior = "reject-foreign";
          Locked = true;
          Allow = lib.lists.remove "" (lib.strings.splitString "\n" (builtins.readFile ../../local/allowed_cookies.txt));
        };
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisableFirefoxAccounts = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DNSOverHTTPS = 
        {
          Enabled = false;
          Locked = true;
        };
        DontCheckDefaultBrowser = true;
        EnableTrackingProtection = 
        {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
          SuspectedFingerprinting = true;
          BaselineExceptions = false;
        };
        GenerativeAI =
        {
          Enabled = false;
          Locked = true;
        };
        HttpsOnlyMode = "force_enabled";
        NoDefaultBookmarks = true;
        NetworkPrediction = false;
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        PostQuantumKeyAgreementEnabled = true;
      };
    };
  };
}