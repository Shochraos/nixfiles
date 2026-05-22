{
  lib,
  stdenv,
  fetchFromGitHub,
  gettext,
  blueprint-compiler,
  python3,
  meson,
  ninja,
  pkg-config,
  gobject-introspection,
  wrapGAppsHook4,
  glib,
  glib-networking,
  libadwaita,
  libsecret,
  gtk4,
  desktop-file-utils,
  gst_all_1,
  shared-mime-info,
}:

let
  mpris_server = python3.pkgs.buildPythonPackage rec {
    pname = "mpris_server";
    version = "0.9.6";
    format = "setuptools";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-T0ZeDQiYIAhKR8aw3iv3rtwzc+R0PTQuIh6+Hi4rIHQ=";
    };

    propagatedBuildInputs = [
      python3.pkgs.strenum
      python3.pkgs.pydbus
      python3.pkgs.emoji
      python3.pkgs.unidecode
    ];

    doCheck = false;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nocturne";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "Jeffser";
    repo = "Nocturne";
    tag = finalAttrs.version;
    hash = "sha256-nW8DCziEERN6xamT+eS6eGTnoNWG6OTdgLb4E2FIzXQ=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gettext
    blueprint-compiler
    gobject-introspection
    wrapGAppsHook4
    desktop-file-utils
    shared-mime-info
  ];

  buildInputs = [
    (python3.withPackages (ps: [
      ps.pygobject3
      ps.tinytag
      ps.requests
      ps.urllib3
      ps.pillow
      ps.strenum
      ps.pydbus
      ps.emoji
      ps.unidecode
      ps.syncedlyrics
      ps.colorthief
      mpris_server
    ]))
    glib
    glib-networking
    gtk4
    libadwaita
    libsecret
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

  meta = with lib; {
    description = "An Adwaita Music Player / Library Manager";
    homepage = "https://github.com/Jeffser/Nocturne";
    license = licenses.gpl3Only;
    mainProgram = "nocturne";
    platforms = platforms.all;
  };
})