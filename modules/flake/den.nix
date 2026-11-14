{
  inputs,
  den,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];

  den.aspects.base.includes = with den.aspects; [
    boot
    secrets
    nix
    attic
    locale
    network
    git
    ssh
    shell
    utilities
  ];

  den.aspects.graphical.includes = with den.aspects; [
    base
    hyprland
    apps
    discord
    audio
    theming
    plymouth
    terminal
    duxshell
    browser
    editor
    sync
    printing
    bluetooth
  ];

  den.aspects.azazel.includes = with den.aspects; [
    graphical
    scheduling
    wireguard
    wifi
    kde-connect
    cpu-amd
    nvidia
    gaming
    ai-harness
    #ai-stt
    irc
    media
    mounts
    gamechat
    lgtv
    #mp3tag
    backup
    crypto
  ];

  den.aspects.solas.includes = with den.aspects; [
    graphical
    scheduling
    wireguard
    wifi
    laptop
    cpu-amd
    fingerprint
    mic-mute
    ai-harness
    unreal
    mounts
  ];

  den.aspects.seere.includes = with den.aspects; [
    base
    dns-server
    reverse_proxy
  ];
  den.aspects.sitri.includes = with den.aspects; [
    base
    dns-server
  ];

  den.hosts.x86_64-linux.Azazel = {
    aspect = den.aspects.azazel;
    users.shochraos.classes = [ "homeManager" ];
  };

  den.hosts.x86_64-linux.Solas = {
    aspect = den.aspects.solas;
    users.shochraos.classes = [ "homeManager" ];
  };

  den.hosts.x86_64-linux.Seere = {
    aspect = den.aspects.seere;
    users.shochraos.classes = [ "homeManager" ];
  };

  den.hosts.x86_64-linux.Sitri = {
    aspect = den.aspects.sitri;
    users.shochraos.classes = [ "homeManager" ];
  };
}
