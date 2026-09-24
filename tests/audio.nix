{
  lib,
  harness,
  audioPath,
}:
let
  aspect = harness.nixos audioPath [
    "audio"
    "nixos"
  ];

  preset = {
    bands = [ ];
  };

  eq =
    {
      default ? "arya-organic",
      presets ? {
        arya-organic = preset;
        flat = preset;
      },
    }:
    {
      target = {
        "api.alsa.card.name" = "Topping DX3 Pro";
      };
      preamp = 0.0;
      inherit default presets;
    };

  failures =
    equalizers:
    map (a: a.message) (
      builtins.filter (a: !a.assertion)
        (aspect (harness.aspectArgs { host.audio.equalizers = equalizers; })).assertions
    );

  onlyFailureMentions =
    equalizers: needle:
    let
      failed = failures equalizers;
    in
    builtins.length failed == 1 && lib.hasInfix needle (builtins.head failed);
in
{
  testEqualizerAssertionsAllHold = {
    expr = failures { dx3 = eq { }; };
    expected = [ ];
  };

  testEqualizerDefaultMustBeAPreset = {
    expr = onlyFailureMentions { dx3 = eq { default = "house"; }; } ".default is";
    expected = true;
  };

  testEqualizerNamesRejectIllegalCharacters = {
    expr = onlyFailureMentions { "dx 3" = eq { }; } "must match [a-zA-Z0-9-]+";
    expected = true;
  };

  testEqualizerRejectsReservedOffPreset = {
    expr = onlyFailureMentions {
      dx3 = eq {
        presets = {
          arya-organic = preset;
          flat = preset;
          off = preset;
        };
      };
    } ''"off" is reserved'';
    expected = true;
  };

  testNoEqualizersEmitNoAssertions = {
    expr = failures { };
    expected = [ ];
  };
}
