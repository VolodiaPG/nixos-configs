# ponytail: high-tide fork — upstream buildPythonApplication verbatim from high-tide/flake.nix,
# only `src` swapped from `./.` to the npins pin. Upstream is pure (no flake refs in the expr).
# Re-add upstream's `nativeBuildInputs`/`buildInputs`/`dependencies` if they change the flake.
{
  python313Packages,
  wrapGAppsHook4,
  meson,
  ninja,
  pkg-config,
  blueprint-compiler,
  desktop-file-utils,
  libadwaita,
  glib-networking,
  gst_all_1,
  libsecret,
  libportal,
  alsa-utils,
  pipewire,
  src,
}:
let
  nativeBuildInputs = [
    wrapGAppsHook4
    meson
    ninja
    pkg-config
    blueprint-compiler
    desktop-file-utils
  ];
  buildInputs = [
    glib-networking
    libadwaita
    libportal
    pipewire # provides a gstreamer plugin for pipewiresink
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    libsecret
  ]);
  dependencies = [
    alsa-utils
  ]
  ++ (with python313Packages; [
    pygobject3
    tidalapi
    requests
    python-mpd2
    pypresence
  ]);
in
python313Packages.buildPythonApplication {
  name = "high-tide";
  pyproject = false;
  inherit src;
  inherit nativeBuildInputs buildInputs dependencies;

  dontWrapGApps = true;
  makeWrapperArgs = [ "\${gappsWrapperArgs[@]}" ];

  meta = {
    description = "Libadwaita TIDAL client for Linux";
    homepage = "https://github.com/Nokse22/high-tide";
    mainProgram = "high-tide";
  };
}
