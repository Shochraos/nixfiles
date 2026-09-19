{ harness, hdrPath }:
let
  aspect = harness.homeManager hdrPath [
    "hdr"
    "provides"
    "to-users"
    "homeManager"
  ];

  hdrPackages =
    outputs:
    harness.packageDrvPaths
      (aspect ({ osConfig.host = { inherit outputs; }; } // harness.aspectArgs { })).home.packages;
in
{
  testHdrOutputRejectsNone = {
    expr = builtins.deepSeq (hdrPackages { "DP-1" = harness.output { }; }) "no-throw";
    expectedError.msg = "expected exactly one host.outputs entry with hdr = true, got 0";
  };

  testHdrOutputRejectsTwo = {
    expr = builtins.deepSeq (hdrPackages {
      "DP-1" = harness.output { hdr = true; };
      "HDMI-A-1" = harness.output { hdr = true; };
    }) "no-throw";
    expectedError.msg = "expected exactly one host.outputs entry with hdr = true, got 2";
  };
}
