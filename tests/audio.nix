{ harness, audioPath }:
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

  verdicts =
    equalizers:
    map (a: a.assertion)
      (aspect (harness.aspectArgs { host.audio.equalizers = equalizers; })).assertions;
in
{
  testEqualizerAssertionsAllHold = {
    expr = verdicts { dx3 = eq { }; };
    expected = [
      true
      true
      true
    ];
  };

  testEqualizerDefaultMustBeAPreset = {
    expr = verdicts { dx3 = eq { default = "house"; }; };
    expected = [
      false
      true
      true
    ];
  };

  testEqualizerNamesRejectIllegalCharacters = {
    expr = verdicts { "dx 3" = eq { }; };
    expected = [
      true
      false
      true
    ];
  };

  testEqualizerRejectsReservedOffPreset = {
    expr = verdicts {
      dx3 = eq {
        presets = {
          arya-organic = preset;
          flat = preset;
          off = preset;
        };
      };
    };
    expected = [
      true
      true
      false
    ];
  };

  testNoEqualizersEmitNoAssertions = {
    expr = verdicts { };
    expected = [ ];
  };
}
