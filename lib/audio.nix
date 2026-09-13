{ lib }:
let
  safeName = name: builtins.match "[a-zA-Z0-9-]+" name != null;
in
{
  assertionsFor =
    equalizers:
    lib.concatLists (
      lib.mapAttrsToList (name: equalizer: [
        {
          assertion = equalizer.presets ? ${equalizer.default};
          message = "host.audio.equalizers.${name}.default is \"${equalizer.default}\", which is not one of its presets (${lib.concatStringsSep ", " (builtins.attrNames equalizer.presets)}).";
        }
        {
          assertion = safeName name && builtins.all safeName (builtins.attrNames equalizer.presets);
          message = "host.audio.equalizers.${name}: the filter name and every preset name must match [a-zA-Z0-9-]+, because both become systemd unit and store path components.";
        }
        {
          assertion = !(equalizer.presets ? "off");
          message = "host.audio.equalizers.${name}: \"off\" is reserved by eq for running no filter at all and cannot be a preset name.";
        }
      ]) equalizers
    );
}
