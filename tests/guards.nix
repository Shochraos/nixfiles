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
}
