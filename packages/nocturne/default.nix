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
  libadwaita,
  libsecret,
  gtk4,
  desktop-file-utils,
  gst_all_1,
  shared-mime-info,
}:

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
    (python3.withPackages (ps: [ ps.pygobject3 ]))
    glib
    gtk4
    libadwaita
    libsecret
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
  ]);

  meta = with lib; {
    description = "An Adwaita Music Player / Library Manager";
    homepage = "https://github.com/Jeffser/Nocturne";
    license = licenses.gpl3Only;
    mainProgram = "nocturne";
    platforms = platforms.all;
  };
})