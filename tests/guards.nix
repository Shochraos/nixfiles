{ lib, aiPath }:
let
  ai =
    (import aiPath {
      den = {
        aspects = { };
      };
      inputs = { };
      inherit lib;
      config = {
        assets = { };
      };
    }).den.aspects.ai;
  callAi =
    args:
    ai.__functor {
      tools = "tools";
      stt = "stt";
      local = "local";
    } args;
in
{
  testAiRejectsNonAttrs = {
    expr = ai [ "stt" ];
    expectedError.msg = "must be called with an argument set";
  };

  testAiRejectsUnknownArgument = {
    expr = ai {
      stt = true;
      tts = true;
    };
    expectedError.msg = "unknown argument\\(s\\) tts";
  };

  testAiIncludesToolsAndOnlyTheRequestedFeature = {
    expr = (callAi { stt = true; }).includes;
    expected = [
      "tools"
      "stt"
    ];
  };

  testAiLeavesOutFeaturesByDefault = {
    expr = (callAi { }).includes;
    expected = [ "tools" ];
  };
}
