{ harness, hyprlandConfigPath }:
let
  aspect = harness.homeManager hyprlandConfigPath [
    "hyprland"
    "provides"
    "to-users"
    "homeManager"
  ];

  settings =
    outputs:
    (aspect (
      {
        osConfig.host = {
          inherit outputs;
          hyprland = {
            settings = { };
            gestures = [ ];
            workspaceRules = [ ];
          };
        };
      }
      // harness.aspectArgs { }
    )).wayland.windowManager.hyprland.settings;
in
{
  testMonitorRulesSkipsUnpinnedOutputs = {
    expr = (settings { "DP-1" = harness.output { }; }).monitor;
    expected = [ ];
  };

  testMonitorRulesEmitsOnlyPinnedFields = {
    expr =
      (settings {
        "DP-1" = harness.output {
          mode = "3440x1440@144";
          position = "0x0";
        };
      }).monitor;
    expected = [
      {
        output = "DP-1";
        mode = "3440x1440@144";
        position = "0x0";
      }
    ];
  };

  testWorkspaceRulesMarkOnlyTheFirstWorkspaceDefault = {
    expr =
      (settings {
        "HDMI-A-1" = harness.output {
          workspaces = [
            1
            2
          ];
        };
      }).workspace_rule;
    expected = [
      {
        workspace = "1";
        monitor = "HDMI-A-1";
        persistent = true;
        default = true;
      }
      {
        workspace = "2";
        monitor = "HDMI-A-1";
        persistent = true;
      }
    ];
  };

  testWorkspaceRulesEmptyForOutputWithNoWorkspaces = {
    expr = (settings { "DP-1" = harness.output { }; }).workspace_rule;
    expected = [ ];
  };
}
