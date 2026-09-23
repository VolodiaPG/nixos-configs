# RIFE frame interpolation via vs-mlrt (TensorRT backend).
# Bound to 'r' in input.conf. 2x the source frame rate, v4.26 model.
import os

import vapoursynth as vs
import vsmlrt
from vsmlrt import RIFE, Backend, RIFEModel

core = vs.core
core.num_threads = 4

# vsmlrt.py's own LoadPlugin guard only runs the first time the module is
# imported in this process, but mpv hands each video its own fresh core
# without the plugin loaded. Load it again here, every script evaluation.
if not hasattr(core, "trt"):
    core.std.LoadPlugin(path=os.path.join(vsmlrt.plugins_path, "libvstrt.so"))
if not hasattr(core, "misc"):
    core.std.LoadPlugin(path=os.path.join(vsmlrt.plugins_path, "libmiscfilters.so"))

# TensorRT engines are compiled on first use for this exact model + resolution
# + GPU, which takes a minute or so; keep them out of the read-only nix store.
engine_dir = os.path.join(
    os.getenv("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "vsmlrt"
)
os.makedirs(engine_dir, exist_ok=True)

clip = video_in

# clip = core.misc.SCDetect(clip, threshold=0.2)

# RGBH (half-precision float RGB) is what the fp16 engine wants.
clip = core.resize.Bilinear(clip, format=vs.RGBH, matrix_in_s="709")

clip = RIFE(
    clip,
    multi=2,
    model=RIFEModel.v4_7,
    ensemble=False,
    # scale=0.5,
    backend=Backend.TRT(
       num_streams=4,
       fp16=True,
       output_format=1,
       use_cuda_graph=True,
       engine_folder=engine_dir,
       workspace = 10 * 1024 ** 3,
       use_jit_convolutions=True,
       use_cudnn=True,
       static_shape=True,
       use_cublas=True,
       force_fp16=True,
       heuristic=True,
    ),
    video_player=True,
    # Implementation 2 pads internally; implementation 1 (the default) rejects
    # any frame size that is not a multiple of 64, i.e. most real video.
    _implementation=2,
)

clip = core.resize.Bilinear(clip, format=vs.YUV420P8, matrix_s="709")
clip.set_output()
