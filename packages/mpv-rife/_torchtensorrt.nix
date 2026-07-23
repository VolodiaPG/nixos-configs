{
  buildPythonPackage,
  fetchurl,
  lib,
  python,
  tensorrt,
  torch,
}:
# https://github.com/ConnorBaker/ContinuousSR/blob/bce62eee6355abaa4e735ffb1f1c41957ec3deec/torch-tensorrt.nix
buildPythonPackage.override { inherit (torch) stdenv; } {
  pname = "torch-tensorrt";
  version = "2.10.0";

  format = "wheel";

  # Building the source would require integrating Bazel and Python and I don't want to do that.
  src = fetchurl {
    name = "torch_tensorrt-2.10.0+cu129-cp313-cp313-manylinux_2_28_x86_64.whl";
    url = "https://download.pytorch.org/whl/cu129/torch_tensorrt-2.10.0%2Bcu129-cp313-cp313-manylinux_2_28_x86_64.whl";
    hash = "sha256-WTd3cpigHupEu3bT9x54kQenePc8IWr/PuHTKamcmzw=";
  };

  preFixup = ''
    nixLog "patching $out/${python.sitePackages}/torch_tensorrt/_features.py to avoid dllist dependency"
    substituteInPlace "$out/${python.sitePackages}/torch_tensorrt/_features.py" \
      --replace-fail \
        '_WINDOWS_CROSS_COMPILE = check_cross_compile_trt_win_lib()' \
        '_WINDOWS_CROSS_COMPILE = False'
  '';

  # TODO: Somehow torch is propagating ninja, causing
  # ```
  # python3.13-torch-tensorrt> Running phase: buildPhase
  # python3.13-torch-tensorrt> build flags: -j32
  # python3.13-torch-tensorrt> /nix/store/fj2ynggnyq1a3w19ypz74ac27z8faf14-python3.13-ninja-1.13.1/nix-support/setup-hook: line 19: ninja: command not found
  # ```
  dontUseNinjaBuild = true;

  # Wheel metadata pins torch<2.11.0,>=2.10.0 but nixpkgs has 2.12.0.
  # PyTorch maintains C++ ABI compatibility within 2.x, so 2.12 should link fine.
  dontCheckRuntimeDeps = true;

  dependencies = [
    torch
    tensorrt
  ];

  # Importing torch_tensorrt links both libtorch and libnvinfer, so a successful
  # import proves their ABIs are compatible. It also initializes CUDA, which is
  # slow but unavoidable for this check.
  # pythonImportsCheck = [ "torch_tensorrt" ];

  meta = {
    description = "PyTorch/TorchScript/FX compiler for NVIDIA GPUs using TensorRT";
    homepage = "https://github.com/pytorch/TensorRT";
    license = lib.licenses.bsd3;
    # broken = !torch.cudaSupport;
    platforms = [
      # "aarch64-linux" # TODO: Package the ARM version as well... and the Jetson version?
      "x86_64-linux"
    ];
    maintainers = with lib.maintainers; [ ConnorBaker ];
  };
}
