{ inputs, ... }:
{
  den.aspects.browser =
    { host, user, ... }:
    {
      nixos =
        { config, lib, ... }:
        let
          cookiesSecret = "zen/allowed-cookies/${lib.toLower host.name}";
          cookiesMarker = "@ALLOWED_COOKIES@";

          policies = {
            ExtensionSettings =
              builtins.mapAttrs
                (_: pluginId: {
                  install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
                  installation_mode = "force_installed";
                })
                {
                  "uBlock0@raymondhill.net" = "ublock-origin";
                  "sponsorBlocker@ajay.app" = "sponsorblock";
                  "firefox@tampermonkey.net" = "tampermonkey";
                  "CanvasBlocker@kkapsner.de" = "canvasblocker";
                  "@testpilot-containers" = "multi-account-containers";
                  "78272b6fa58f4a1abaac99321d503a20@proton.me" = "proton-pass";
                };

            SearchEngines = {
              Default = "DuckDuckGo";
              PreventInstalls = false;
              Remove = [
                "Google"
                "Bing"
                "Amazon.com"
                "eBay"
                "Twitter"
                "Wikipedia"
                "Perplexity"
                "Youtube"
              ];
              Add = [
                {
                  Name = "NixPkgs";
                  URLTemplate = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
                  Method = "GET";
                  IconURL = "https://nixos.org/favicon.ico";
                  Alias = "@np";
                }
              ];
            };

            Cookies = {
              Allow = cookiesMarker;
              Behavior = "reject-foreign";
              Locked = true;
            };

            DNSOverHTTPS = {
              Enabled = false;
              Locked = true;
            };

            EnableTrackingProtection = {
              BaselineExceptions = false;
              Cryptomining = true;
              EmailTracking = true;
              Fingerprinting = true;
              Locked = true;
              SuspectedFingerprinting = true;
              Value = true;
            };

            FirefoxHome = {
              Highlights = false;
              Locked = true;
              Pocket = false;
              Search = true;
              Snippets = false;
              SponsoredPocket = false;
              SponsoredTopSites = false;
              TopSites = true;
            };

            FirefoxSuggest = {
              ImprovementVideo = false;
              Locked = true;
              SponsoredSuggestions = false;
              WebSuggestions = false;
            };

            GenerativeAI = {
              Enabled = false;
              Locked = true;
            };

            InstallAddonsPermission = {
              Default = false;
            };

            UserMessaging = {
              ExtensionRecommendations = false;
              FeatureRecommendations = false;
              Locked = true;
              SkipOnboarding = true;
              UrlbarInterventions = false;
              WhatsNew = false;
            };

            AutofillAddressEnabled = true;
            AutofillCreditCardEnabled = false;
            BlockAboutAddons = true;
            DisableAppUpdate = true;
            DisableFeedbackCommands = true;
            DisableFirefoxAccounts = true;
            DisableFirefoxScreenshots = true;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            DisableSetDesktopBackground = true;
            DisableTelemetry = true;
            DontCheckDefaultBrowser = true;
            HttpsOnlyMode = "force_enabled";
            NetworkPrediction = false;
            NoDefaultBookmarks = true;
            OfferToSaveLogins = false;
            OverrideFirstRunPage = "";
            OverridePostUpdatePage = "";
            PasswordManagerEnabled = false;
            PostQuantumKeyAgreementEnabled = true;
          };
        in
        {
          programs.firefox.enable = false;

          sops.secrets.${cookiesSecret} = { };

          sops.templates."zen-policies.json" = {
            owner = user.name;
            content =
              builtins.replaceStrings
                [ (builtins.toJSON cookiesMarker) ]
                [ config.sops.placeholder.${cookiesSecret} ]
                (builtins.toJSON { inherit policies; });
          };

          environment.etc."zen/policies/policies.json".source =
            config.sops.templates."zen-policies.json".path;
        };

      provides.to-users.homeManager =
        { config, ... }:
        {
          imports = [ inputs.zen-browser.homeModules.beta ];

          xdg.autostart = {
            entries = [
              "${config.programs.zen-browser.package}/share/applications/zen-beta.desktop"
            ];
          };

          programs.zen-browser = {
            enable = true;

            profiles."Nix-Zen" = {
              isDefault = true;

              settings = {
                "app.normandy.api_url" = "";
                "app.normandy.enabled" = false;
                "browser.aboutConfig.showWarning" = false;
                "browser.download.panel.shown" = false;
                "browser.search.suggest.enabled" = false;
                "browser.tabs.warnOnClose" = false;
                "browser.tabs.warnOnCloseOther" = false;
                "browser.uitour.enabled" = false;
                "findbar.highlightAll" = true;
                "full-screen-api.warning.timeout" = 0;
                "gfx.webrender.all" = true;
                "media.autoplay.default" = 5;
                "media.ffmpeg.vaapi.enabled" = true;
                "media.peerconnection.ice.default_address_only" = true;
                "network.prefetch-next" = false;
                "privacy.donottrackheader.enabled" = true;
                "widget.use-xdg-desktop-portal.file-picker" = 1;

                "network.cookie.lifetimePolicy" = 2;
                "privacy.sanitize.sanitizeOnShutdown" = true;
                "privacy.clearOnShutdown.cookies" = true;
                "privacy.clearOnShutdown.cache" = true;
                "privacy.clearOnShutdown.history" = false;
                "privacy.clearOnShutdown.sessions" = false;

                "widget.wayland.fractional-scale.enabled" = true;
                "apz.overscroll.enabled" = true;

                "browser.tabs.closeWindowWithLastTab" = false;
                "browser.compactmode.show" = true;
                "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              };
            };
          };
        };
    };
}
