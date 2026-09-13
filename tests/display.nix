{ lib, displayPath }:
let
  display = import displayPath { inherit lib; };

  output =
    extra:
    {
      primary = false;
      hdr = false;
      wideColor = false;
      vrrFullscreenOnly = false;
      bitdepth = null;
      mode = null;
      position = null;
      scale = null;
      workspaces = [ ];
    }
    // extra;
in
{
  testMonitorRulesSkipsUnpinnedOutputs = {
    expr = display.monitorRules { "DP-1" = output { }; };
    expected = [ ];
  };

  testMonitorRulesEmitsOnlyPinnedFields = {
    expr = display.monitorRules {
      "DP-1" = output {
        mode = "3440x1440@144";
        position = "0x0";
      };
    };
    expected = [
      {
        output = "DP-1";
        mode = "3440x1440@144";
        position = "0x0";
      }
    ];
  };

  testWorkspaceRulesMarkOnlyTheFirstWorkspaceDefault = {
    expr = display.workspaceRules {
      "HDMI-A-1" = output {
        workspaces = [
          1
          2
        ];
      };
    };
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
    expr = display.workspaceRules { "DP-1" = output { }; };
    expected = [ ];
  };

  testBarScreensAllWhenNoPrimary = {
    expr = display.barScreens {
      "DP-1" = output { };
      "HDMI-A-1" = output { };
    };
    expected = [ "all" ];
  };

  testBarScreensPinsToOnePrimary = {
    expr = display.barScreens {
      "DP-1" = output { };
      "HDMI-A-1" = output { primary = true; };
    };
    expected = [ "HDMI-A-1" ];
  };

  testBarScreensRejectsTwoPrimaries = {
    expr = display.barScreens {
      "DP-1" = output { primary = true; };
      "HDMI-A-1" = output { primary = true; };
    };
    expectedError.msg = "at most one host.outputs entry may set primary = true, got 2";
  };

  testHdrOutputSelectsTheSingleHdrEntry = {
    expr = display.hdrOutput {
      "DP-1" = output { };
      "HDMI-A-1" = output { hdr = true; };
    };
    expected = "HDMI-A-1";
  };

  testHdrOutputRejectsNone = {
    expr = display.hdrOutput { "DP-1" = output { }; };
    expectedError.msg = "exactly one host.outputs entry with hdr = true, got 0";
  };

  testHdrOutputRejectsTwo = {
    expr = display.hdrOutput {
      "DP-1" = output { hdr = true; };
      "HDMI-A-1" = output { hdr = true; };
    };
    expectedError.msg = "exactly one host.outputs entry with hdr = true, got 2";
  };
}
