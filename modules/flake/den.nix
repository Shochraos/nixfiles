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
    shell
    remotes
    wireguard
    wifi
  ];

  den.aspects.gaming.includes = with den.aspects; [
    hdr
    (den.batteries.unfree [
      "steam"
      "steam-unwrapped"
    ])
  ];
  den.aspects.media.includes = with den.aspects; [ hdr ];
  den.aspects.apps.includes = [
    (den.batteries.unfree [
      "discord"
      "spotify"
    ])
  ];
  den.aspects.nvidia.includes = [ (den.batteries.unfree [ "nvidia-x11" ]) ];

  den.aspects.graphical.includes = with den.aspects; [
    base
    hyprland
    terminal
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
    graphical
    desktop
    cpu-amd
    nvidia
    gaming
    (ai {
      local = false;
      stt = true;
    })
    irc
    media
    remote-mounts
    virtualization
    gamechat
    lgtv
    mp3tag
  ];

  den.aspects.solas.includes = with den.aspects; [
    graphical
    laptop
    cpu-amd
    fingerprint
    virtualization
    mic-mute
    (ai {
      local = false;
      stt = false;
    })
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
