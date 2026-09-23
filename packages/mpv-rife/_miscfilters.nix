{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  vapoursynth,
}:
stdenv.mkDerivation {
  pname = "vapoursynth-miscfilters";
  # ponytail: no tag newer than R2 (2017) exists, but R2 predates the meson
  # build entirely (it shipped only an msvc project); pin the last commit on
  # master instead, which is the one that added meson.build.
  version = "unstable-2022-01-24";

  src = fetchFromGitHub {
    owner = "vapoursynth";
    repo = "vs-miscfilters-obsolete";
    rev = "07e0589a381f7deb3bf533bb459a94482bccc5c7";
    hash = "sha256-WEhpBTNEamNfrNXZxtpTGsOclPMRu+yBzNJmDnU0wzQ=";
  };

  # Upstream derives install_dir from vapoursynth's own pkgconfig libdir
  # (an absolute path outside $out); pin it relative so it lands in
  # $out/lib/vapoursynth like vstrt, letting the two be symlinkJoin'd.
  postPatch = ''
    substituteInPlace meson.build --replace-fail \
      "install_dir : join_paths(dep.get_pkgconfig_variable('libdir'), 'vapoursynth')," \
      "install_dir : 'lib/vapoursynth',"
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];
  buildInputs = [ vapoursynth ];

  meta = {
    description = "MiscFilters plugin for VapourSynth (SCDetect and others)";
    homepage = "https://github.com/vapoursynth/vs-miscfilters-obsolete";
    license = lib.licenses.lgpl21Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
