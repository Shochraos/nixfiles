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
    boot
    secrets
    nix
    locale
    network
    audio
    scheduling
    shell
    remotes
    wireguard
    wifi
  ];

  den.aspects.graphical.includes = with den.aspects; [
    base
    hyprland
    theming
    plymouth
    terminal
    duxshell
    browser
    editor
    apps
    sync
    printing
    bluetooth
  ];

  den.aspects.azazel.includes = with den.aspects; [
    graphical
    desktop
    kde-connect
    cpu-amd
    nvidia
    gaming
    ai-harness
    ai-stt
    irc
    media
    remote-mounts
    gamechat
    lgtv
    mp3tag
    backup
    crypto
  ];

  den.aspects.solas.includes = with den.aspects; [
    graphical
    laptop
    cpu-amd
    fingerprint
    mic-mute
    ai-harness
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
