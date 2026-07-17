{
  inputs,
  lib,
  den,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.aspects.base.includes = with den.aspects; [
    hostOptions
    boot
    secrets
    nix
    locale
    network
    audio
    scheduling
    terminal
    shell
    remotes
    wireguard
    wifi
  ];

  den.aspects.desktop.includes = with den.aspects; [
    base
    hyprland
    dankshell
    browser
    editor
    apps
    sync
    kde-connect
    printing
    bluetooth
  ];

  den.aspects.azazel.includes = with den.aspects; [
    desktop
    cpu-amd
    gaming
    ai
    media
    remote-mounts
    virtualization
    gamechat
    lgtv
    mp3tag
    preventsleep
  ];

  den.aspects.solas.includes = with den.aspects; [
    desktop
    cpu-amd
    fingerprint
    virtualization
    mic-mute
  ];

  den.hosts.x86_64-linux.Azazel = {
    aspect = den.aspects.azazel;
    users.shochraos = { };
  };

  den.hosts.x86_64-linux.Solas = {
    aspect = den.aspects.solas;
    users.shochraos = { };
  };
}
