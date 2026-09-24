{ harness, dankshellPath }:
let
  aspect = harness.homeManager dankshellPath [
    "dankshell"
    "provides"
    "to-users"
    "homeManager"
  ];

  settings =
    outputs: bars:
    (aspect (
      {
        osConfig.host = {
          inherit outputs;
          dms.barConfigs = bars;
        };
      }
      // harness.aspectArgs { }
    )).programs.dank-material-shell.settings;

  screenPreferences =
    outputs: (builtins.head (settings outputs harness.barConfig).barConfigs).screenPreferences;
in
{
  testBarScreensAllWhenNoPrimary = {
    expr = screenPreferences {
      "DP-1" = harness.output { };
      "HDMI-A-1" = harness.output { };
    };
    expected = [ "all" ];
  };

  testBarScreensPinsToOnePrimary = {
    expr = screenPreferences {
      "DP-1" = harness.output { };
      "HDMI-A-1" = harness.output { primary = true; };
    };
    expected = [ "HDMI-A-1" ];
  };

  testBarScreensRejectsTwoPrimaries = {
    expr = screenPreferences {
      "DP-1" = harness.output { primary = true; };
      "HDMI-A-1" = harness.output { primary = true; };
    };
    expectedError.msg = "at most one host.outputs entry may set primary = true, got 2";
  };

  testBarConfigsHostEntriesOverrideDefaults = {
    expr =
      let
        bar =
          builtins.head
            (settings { "DP-1" = harness.output { }; } [
              {
                id = "custom";
                screenPreferences = [ "DP-1" ];
              }
            ]).barConfigs;
      in
      {
        inherit (bar) id name screenPreferences;
      };
    expected = {
      id = "custom";
      name = "Main Bar";
      screenPreferences = [ "DP-1" ];
    };
  };

  testHyprlandOutputSettingsMapsOnlySetFields = {
    expr =
      (settings {
        "HDMI-A-1" = harness.output {
          hdr = true;
          wideColor = true;
          bitdepth = 10;
          vrrFullscreenOnly = true;
        };
        "DP-1" = harness.output { bitdepth = 8; };
        "eDP-1" = harness.output { };
      } harness.barConfig).hyprlandOutputSettings;
    expected = {
      "HDMI-A-1" = {
        bitdepth = 10;
        vrrFullscreenOnly = true;
        supportsHdr = true;
        supportsWideColor = true;
      };
      "DP-1" = {
        bitdepth = 8;
      };
      "eDP-1" = { };
    };
  };
}
