{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  fetchurl,
  hatchling,
  vapoursynth,
  numpy,
  tqdm,
  torch,
  requests,
}:
let
  modelFile = fetchurl {
    url = "https://github.com/HolyWu/vs-rife/releases/download/model/flownet_v4.25.pkl";
    hash = "sha256-ZhV5Dv1id3KRcgXbKR9RzTklKKFX7Lsuyu7Dv/jrbeI=";
    name = "flownet_v4.25.pkl";
  };
in
buildPythonPackage (finalAttrs: {
  pname = "vs-rife";
  version = "3488617283db7c428a83ba4a19382285da698b6a";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "HolyWu";
    repo = "vs-rife";
    rev = "3488617283db7c428a83ba4a19382285da698b6a";
    hash = "sha256-k1vudIKg45m1uiXZb+blvYLkctD7IoQzl3lutxKp4vY=";
  };

  build-system = [ hatchling ];

  dependencies = [
    vapoursynth
    numpy
    torch
    tqdm
    requests
  ];

  preBuild = ''
    mkdir -p vsrife/models
    cp ${modelFile} vsrife/models/flownet_v4.25.pkl
  '';

  # pythonImportsCheck = [ "vsrife" ];

  meta = with lib; {
    description = "VapourSynth Real-Time Intermediate Flow Estimation";
    homepage = "https://github.com/HolyWu/vs-rife";
    license = licenses.mit;
    maintainers = [ ];
  };
})
