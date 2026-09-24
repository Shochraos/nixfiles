{
  lib,
  harness,
  hyprlandRulesPath,
  streamingPath,
}:
let
  rulesAspect = harness.homeManager hyprlandRulesPath [
    "hyprland"
    "provides"
    "to-users"
    "homeManager"
  ];

  streamingAspect = harness.homeManager streamingPath [
    "gaming"
    "provides"
    "to-users"
    "homeManager"
  ];

  hyprland =
    streaming:
    (rulesAspect (
      {
        osConfig.host = {
          inherit streaming;
          hyprland.windowRules = [ ];
        };
      }
      // harness.aspectArgs { }
    )).wayland.windowManager.hyprland;

  gamescopeRules =
    streaming:
    builtins.filter (rule: rule.match.class or "" == "^(gamescope)$")
      (hyprland streaming).settings.window_rule;

  deck =
    extra:
    {
      output = "DECK";
      mode = "1280x720@90";
      scale = null;
    }
    // extra;

  streamingWith =
    displays:
    streamingAspect ({ osConfig.host.streaming = { inherit displays; }; } // harness.aspectArgs { });

  geometryVerdict =
    mode:
    builtins.deepSeq (harness.packageDrvPaths
      (streamingWith { deck = deck { inherit mode; }; }).home.packages
    ) "no-throw";
in
{
  testStreamingWindowRulesSkipAnEmptyDisplayTable = {
    expr = gamescopeRules { displays = { }; };
    expected = [ ];
  };

  testStreamingWindowRulesMatchGamescopeOnAnyOutput = {
    expr = gamescopeRules { displays.deck = deck { }; };
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
    expr = harness.packageDrvPaths (streamingWith { }).home.packages;
    expected = [ ];
  };

  testStreamingLuaIsEmptyWithoutAScript = {
    expr = (hyprland { displays = { }; }).extraConfig;
    expected = "";
  };

  testStreamingLuaRegistersStartAndReloadHooks = {
    expr =
      let
        lua = (hyprland { displays.deck = deck { }; }).extraConfig;
      in
      {
        start = lib.hasInfix ''hl.on("hyprland.start"'' lua;
        reload = lib.hasInfix ''hl.on("config.reloaded"'' lua;
        invoke = lib.hasInfix "/bin/streaming-displays" lua;
      };
    expected = {
      start = true;
      reload = true;
      invoke = true;
    };
  };

  testStreamingGeometryRejectsAModeWithoutARefreshRate = {
    expr = geometryVerdict "2560x1440";
    expectedError.msg = "must be WIDTHxHEIGHT@REFRESH";
  };

  testStreamingGeometryRejectsAMalformedSize = {
    expr = geometryVerdict "2560@120";
    expectedError.msg = "must be WIDTHxHEIGHT@REFRESH";
  };
}
