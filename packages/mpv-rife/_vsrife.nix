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
  model_name = "flownet_v4.6.pkl";
  modelFile = fetchurl {
    url = "https://github.com/HolyWu/vs-rife/releases/download/model/${model_name}";
    hash = "sha256-AIZG52Hw5ny3fwxsRM/jw+WgXZ2UZTEbloHKZQzgMNs=";
    name = model_name;
  };
in
buildPythonPackage (_finalAttrs: {
  pname = "vsrife";
  version = "5.7.0";
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
    cp ${modelFile} vsrife/models/${model_name}
  '';

  # pythonImportsCheck = [ "vsrife" ];

  meta = with lib; {
    description = "VapourSynth Real-Time Intermediate Flow Estimation";
    homepage = "https://github.com/HolyWu/vs-rife";
    license = licenses.mit;
    maintainers = [ ];
  };
})
