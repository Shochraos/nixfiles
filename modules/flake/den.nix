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
    locale
    network
    shell
  ];

  den.aspects.graphical.includes = with den.aspects; [
    base
    audio
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
    scheduling
    remotes
    wireguard
    wifi
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
    scheduling
    remotes
    wireguard
    wifi
    laptop
    cpu-amd
    fingerprint
    mic-mute
    ai-harness
  ];

  den.aspects.seere.includes = with den.aspects; [
    base
    dns-server
    reverse_proxy
  ];
  den.aspects.sitri.includes = with den.aspects; [
    base
    dns-server
    reverse_proxy
  ];

  den.hosts.x86_64-linux.Seere = {
    aspect = den.aspects.seere;
    users.shochraos.classes = [ "homeManager" ];
  };

  den.hosts.x86_64-linux.Sitri = {
    aspect = den.aspects.sitri;
    users.shochraos.classes = [ "homeManager" ];
  };

  den.hosts.x86_64-linux.Azazel = {
    aspect = den.aspects.azazel;
    users.shochraos.classes = [ "homeManager" ];
  };

  den.hosts.x86_64-linux.Solas = {
    aspect = den.aspects.solas;
    users.shochraos.classes = [ "homeManager" ];
  };
}
