{ lib, pkgs }:
let
  stubbedFlakeInputs = {
    dms.homeModules.dank-material-shell = { };
    dms-plugin-registry.homeModules.default = { };
    danksearch.homeModules.dsearch = { };
  };

  fileArgs = {
    inputs = stubbedFlakeInputs;
    inherit lib;
    config = { };
  };

  entityArgs = {
    user.name = "probe";
    host.name = "Probe";
  };

  callIfFunctor = value: if builtins.isFunction value then value entityArgs else value;

  aspectAt =
    path: aspectPath:
    builtins.getAttr (lib.last aspectPath) (
      builtins.foldl' (value: key: callIfFunctor (builtins.getAttr key value))
        (import path fileArgs).den.aspects
        (lib.init aspectPath)
    );
in
{
  homeManager =
    path: aspectPath: innerArgs:
    (aspectAt path aspectPath) innerArgs;

  nixos =
    path: aspectPath: innerArgs:
    (aspectAt path aspectPath) innerArgs;

  aspectArgs = config: {
    inherit config pkgs lib;
  };

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

  barConfig = [ { id = "default"; } ];

  packageDrvPaths = packages: map (package: package.drvPath) packages;
}
