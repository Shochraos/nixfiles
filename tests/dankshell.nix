{ harness, dankshellPath }:
let
  aspect = harness.homeManager dankshellPath [
    "dankshell"
    "provides"
    "to-users"
    "homeManager"
  ];

  screenPreferences =
    outputs:
    let
      barSettings =
        (aspect (
          {
            osConfig.host = {
              inherit outputs;
              dms.barConfigs = harness.barConfig;
            };
          }
          // harness.aspectArgs { }
        )).programs.dank-material-shell.settings;

      firstBar = builtins.head barSettings.barConfigs;
    in
    firstBar.screenPreferences;
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
}
