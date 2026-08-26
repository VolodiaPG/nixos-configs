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
  model_name25 = "flownet_v4.25.pkl";
  modelFile25 = fetchurl {
    url = "https://github.com/HolyWu/vs-rife/releases/download/model/${model_name25}";
    hash = "sha256-ZhV5Dv1id3KRcgXbKR9RzTklKKFX7Lsuyu7Dv/jrbeI=";
    name = model_name25;
  };

  model_name46 = "flownet_v4.6.pkl";
  modelFile46 = fetchurl {
    url = "https://github.com/HolyWu/vs-rife/releases/download/model/${model_name46}";
    hash = "sha256-AIZG52Hw5ny3fwxsRM/jw+WgXZ2UZTEbloHKZQzgMNs=";
    name = model_name46;
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
    cp ${modelFile46} vsrife/models/${model_name46}
    cp ${modelFile25} vsrife/models/${model_name25}
  '';

  # pythonImportsCheck = [ "vsrife" ];

  meta = with lib; {
    description = "VapourSynth Real-Time Intermediate Flow Estimation";
    homepage = "https://github.com/HolyWu/vs-rife";
    license = licenses.mit;
    maintainers = [ ];
  };
})
