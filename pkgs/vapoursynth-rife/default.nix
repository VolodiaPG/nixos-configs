{ lib
, stdenv
, fetchgit
, meson
, pkg-config
, cmake
, ninja
, glslang
, vulkan-headers
, vulkan-loader
, vulkan-validation-layers
, vapoursynth
}:
stdenv.mkDerivation rec {
  name = "VapourSynth-RIFE-ncnn-Vulkan-${version}";
  version = "r9";
  src = fetchgit {
    url = "https://github.com/HomeOfVapourSynthEvolution/VapourSynth-RIFE-ncnn-Vulkan";
    rev = version;
    fetchSubmodules = true;
    sha256 = "sha256-X1c2Eo5QkDELMHo9tP1ue2iZu5qeLatQessfsqmSl60=";
  };

  patches = [ ./fix_lib_path.patch ];

  VULKAN_SDK = "${vulkan-validation-layers}/share/vulkan/explicit_layer.d";

  nativeBuildInputs = [
    meson
    pkg-config
    cmake
    ninja
    glslang
    vulkan-headers
    vulkan-loader
    vulkan-validation-layers
    vapoursynth
  ];

  buildInputs = [
  ];

  enableParallelBuilding = true;

  postUnpack = ''
    ls -l 
  '';

  # postInstall = ''
  #   mkdir -p $out/lib/vapoursynth
  #   cp -r lib/* $out/lib/vapoursynth/
  # '';

  meta = with lib; {
    homepage = "https://github.com/ExpidusOS/libtokyo";
    license = with licenses; [ gpl3Only ];
    maintainers = [ "Tristan Ross" ];
  };
}
