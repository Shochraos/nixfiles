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

  testStreamingWindowRulesEmptyWithoutDisplays = {
    expr = display.streamingWindowRules { displays = { }; };
    expected = [ ];
  };

  testStreamingWindowRulesMatchGamescopeOnAnyOutput = {
    expr = display.streamingWindowRules {
      displays = {
        deck = {
          output = "DECK";
          mode = "1280x800@90";
        };
      };
    };
    expected = [
      {
        match = {
          class = "^(gamescope)$";
        };
        fullscreen = true;
      }
    ];
  };

  testStreamingEnsureScriptIsNullWithoutDisplays = {
    expr = display.streamingEnsureScript {
      pkgs = { };
      streaming = {
        displays = { };
      };
    };
    expected = null;
  };

  testStreamingLuaIsEmptyWithoutAScript = {
    expr = display.streamingLua null;
    expected = "";
  };

  testStreamingLuaRegistersStartAndReloadHooks = {
    expr =
      let
        lua = display.streamingLua "/store/streaming-displays";
        count = needle: builtins.length (lib.splitString needle lua) - 1;
      in
      {
        start = count "hl.on(\"hyprland.start\"";
        reload = count "hl.on(\"config.reloaded\"";
        invoke = count "/store/streaming-displays/bin/streaming-displays";
      };
    expected = {
      start = 1;
      reload = 1;
      invoke = 1;
    };
  };

  # The displays are created at compositor start, so the script must be
  # idempotent: it checks for the output before creating it, and always re-asserts
  # the mode, because a reload collapses the mode without removing the output.
  testStreamingEnsureScriptCreatesThenPinsTheMode =
    let
      drv = display.streamingEnsureScript {
        pkgs = {
          writeShellApplication = args: args;
          gnugrep = "grep";
          jq = "jq";
        };
        streaming = {
          displays = {
            deck = {
              output = "DECK";
              mode = "1280x800@90";
              scale = "1";
            };
          };
        };
      };
      text = drv.text;
      has = needle: builtins.length (lib.splitString needle text) - 1 > 0;
    in
    {
      expr = {
        creates = has ''output create headless "DECK"'';
        pins = has ''hl.monitor({ output = "DECK", mode = "1280x800@90", scale = 1 })'';
      };
      expected = {
        creates = true;
        pins = true;
      };
    };

  testStreamingGeometrySplitsMode = {
    expr = display.streamingGeometry { mode = "2560x1440@120"; };
    expected = {
      width = "2560";
      height = "1440";
      refresh = "120";
    };
  };

  testStreamingGeometryRejectsAModeWithoutARefreshRate = {
    expr = display.streamingGeometry { mode = "2560x1440"; };
    expectedError.msg = "must be WIDTHxHEIGHT@REFRESH";
  };

  testStreamingGeometryRejectsAMalformedSize = {
    expr = display.streamingGeometry { mode = "2560@120"; };
    expectedError.msg = "must be WIDTHxHEIGHT@REFRESH";
  };
}
