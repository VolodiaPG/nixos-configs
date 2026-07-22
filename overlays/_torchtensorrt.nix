{
  buildPythonPackage,
  cudaPackages,
  fetchurl,
  lib,
  python,
  tensorrt,
  torch,
}:
buildPythonPackage {
  pname = "torch-tensorrt";
  version = "2.8.0";

  format = "wheel";

  inherit (torch) stdenv;

  # Building the source would require integrating Bazel and Python and I don't want to do that.
  src = fetchurl {
    name = "torch_tensorrt-2.8.0-cu128-cp313-cp313-manylinux_2_28_x86_64.whl";
    url = "https://download.pytorch.org/whl/cu128/torch_tensorrt-2.8.0%2Bcu128-cp313-cp313-manylinux_2_28_x86_64.whl";
    hash = "sha256-/Qryy6+jh5E6NKLBEfL0NS2b7CbM44/XO17uhZCdJHA=";
  };

  preFixup = ''
    nixLog "patching $out/${python.sitePackages}/torch_tensorrt/__init__.py to fix TensorRT search paths"
    substituteInPlace "$out/${python.sitePackages}/torch_tensorrt/__init__.py" \
      --replace-fail \
        'ctypes.CDLL(_find_lib(lib, LINUX_PATHS))' \
        'ctypes.CDLL(_find_lib(lib, ["${lib.getLib cudaPackages.tensorrt}/lib"]))'

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
  dependencies = [
    torch
    tensorrt
  ];

  # TODO: tests

  # Just trying to import the library initializies CUDA...
  # pythonImportsCheck = [ "torch_tensorrt" ];

  meta = {
    description = "PyTorch/TorchScript/FX compiler for NVIDIA GPUs using TensorRT";
    homepage = "https://github.com/pytorch/TensorRT";
    license = lib.licenses.bsd3;
    broken = !torch.cudaSupport;
    platforms = [
      # "aarch64-linux" # TODO: Package the ARM version as well... and the Jetson version?
      "x86_64-linux"
    ];
    maintainers = with lib.maintainers; [ ConnorBaker ];
  };
}
