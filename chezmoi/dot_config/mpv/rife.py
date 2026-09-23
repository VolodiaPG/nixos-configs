# RIFE frame interpolation via vs-mlrt (TensorRT backend).
# Bound to 'r' in input.conf. 2x the source frame rate.
#
# Backend settings follow the proven baseline from
# https://github.com/We0M/realtime-RIFE-portable (real-time on an RTX 3070):
# only fp16/cuda-graph/static-shape/num_streams are set, no extra tactic
# flags — those were untested cruft that didn't move the needle here.
import os

import vapoursynth as vs
import vsmlrt
from vsmlrt import RIFE, RIFEModel, BackendV2

core = vs.core
core.max_cache_size = 8192  # cap VS frame cache at 8GB RAM

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

# Some sources don't tag their matrix coefficients correctly; guess bt601
# for SD content and bt709 for HD, like the reference script does.
matrix = 1 if (clip.width > 1024 or clip.height >= 600) else 5

# RIFE needs scene-change flags on its input to avoid warping frames across
# cuts (see vsmlrt's own RIFE docstring). Detect on the luma plane, which is
# free for YUV sources since it's just a plane grab, not a conversion.
if clip.format.color_family in (vs.YUV, vs.GRAY):
    sc_clip = core.std.ShufflePlanes(clip, planes=0, colorfamily=vs.GRAY)
else:
    sc_clip = core.resize.Bilinear(clip, format=vs.GRAY8, matrix_in=matrix)
sc_clip = sc_clip.misc.SCDetect(threshold=0.15)

# RGBH (half-precision float RGB) is what the fp16 engine wants.
clip = core.resize.Bicubic(clip, format=vs.RGBH, matrix_in=matrix)
clip = clip.std.CopyFrameProps(sc_clip, ["_SceneChangePrev", "_SceneChangeNext"])

clip = RIFE(
    clip,
    multi=2,
    model=RIFEModel.v4_7,
    backend=BackendV2.TRT(
        output_format=1,
        tf32=False,
        workspace=None,
        fp16=True,
        force_fp16=True,
        use_cuda_graph=True,
        static_shape=True,
        num_streams=2,
        engine_folder=engine_dir,
        max_aux_streams=0,
    ),
    video_player=True,
    # Implementation 2 pads internally; implementation 1 (the default) rejects
    # any frame size that is not a multiple of 64, i.e. most real video.
    _implementation=2,
)

# Keep the source bit depth (most content here is 10-bit) instead of
# truncating to 8-bit.
clip = core.resize.Bicubic(clip, format=vs.YUV420P10, matrix=matrix)
clip.set_output()
