{
  lib,
  stdenv,
  python,
  buildPythonPackage,
  isPyPy,
  fetchurl,

  # nativeBuildInputs
  addDriverRunpath,
  autoAddDriverRunpath,
  autoPatchelfHook,

  # buildInputs
  cudaPackages,

  # dependencies
  filelock,
  fsspec,
  jinja2,
  networkx,
  numpy,
  pyyaml,
  requests,
  setuptools,
  sympy,
  typing-extensions,
  # linux-only
  cuda-bindings,
  # x86_64-linux only
  triton,
}:

# ponytail: torch 2.10.0+cu129 wheel to match torch-tensorrt 2.10.0+cu129 wheel.
# nixpkgs torch is 2.12.0; Library::def ABI changed between 2.10 and 2.12,
# so torch_tensorrt's compiled libtorchtrt.so can't dlopen against 2.12.
buildPythonPackage {
  pname = "torch";
  version = "2.10.0";
  format = "wheel";

  disabled = isPyPy || !stdenv.hostPlatform.isx86_64 || !stdenv.hostPlatform.isLinux;

  src = fetchurl {
    name = "torch-2.10.0+cu129-cp313-cp313-manylinux_2_28_x86_64.whl";
    url = "https://download.pytorch.org/whl/cu129/torch-2.10.0%2Bcu129-cp313-cp313-manylinux_2_28_x86_64.whl";
    hash = "sha256-4RYSbey/vR/G+OB8DRUn8BSwt4e1BHnYRZLMxEhw+NU=";
  };

  nativeBuildInputs = [
    addDriverRunpath
    autoAddDriverRunpath
    autoPatchelfHook
  ];

  buildInputs = with cudaPackages; [
    cuda_nvtx
    cuda_cudart
    cuda_cupti
    cuda_nvrtc
    cudnn
    libcublas
    libcufft
    libcufile
    libcurand
    libcusolver
    libcusparse
    libcusparse_lt
    libnvshmem
    nccl
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"
  ];

  pythonRemoveDeps = [
    "cuda-toolkit"
    "nvidia-cublas"
    "nvidia-cudnn-cu12"
    "nvidia-cusparselt-cu12"
    "nvidia-nccl-cu12"
    "nvidia-nvshmem-cu12"
  ];
  dependencies = [
    filelock
    fsspec
    jinja2
    networkx
    numpy
    pyyaml
    requests
    setuptools
    sympy
    typing-extensions
    cuda-bindings
    triton
  ];

  postInstall = ''
    rm -rf $out/bin
  '';

  postFixup = ''
    addAutoPatchelfSearchPath "$out/${python.sitePackages}/torch/lib"
  '';

  extraRunpaths = [
    "${lib.getLib cudaPackages.cuda_nvrtc}/lib"
  ];
  postPhases = [ "postPatchelfPhase" ];
  postPatchelfPhase = ''
    while IFS= read -r -d $'\0' elf ; do
      for extra in $extraRunpaths ; do
        echo patchelf "$elf" --add-rpath "$extra" >&2
        patchelf "$elf" --add-rpath "$extra"
      done
    done < <(
      find "''${!outputLib}" "$out" -type f -iname '*.so' -print0
    )
  '';

  dontStrip = true;

  dontCheckRuntimeDeps = true;

  # pythonImportsCheck = [ "torch" ];

  meta = {
    description = "PyTorch: Tensors and Dynamic neural networks in Python with strong GPU acceleration";
    license = with lib.licenses; [
      bsd3
      issl
      unfreeRedistributable
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    broken = !cudaPackages ? cuda_nvrtc;
  };
}
