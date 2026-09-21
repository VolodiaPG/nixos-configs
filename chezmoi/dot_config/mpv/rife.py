# RIFE frame interpolation via vs-mlrt (TensorRT backend).
# Bound to 'r' in input.conf. 2x the source frame rate, v4.26 model.
import os

import vapoursynth as vs
import vsmlrt
from vsmlrt import RIFE, BackendV2, RIFEModel

core = vs.core
core.num_threads = 8

# vsmlrt.py's own LoadPlugin guard only runs the first time the module is
# imported in this process, but mpv hands each video its own fresh core
# without the plugin loaded. Load it again here, every script evaluation.
if not hasattr(core, "trt"):
    core.std.LoadPlugin(path=os.path.join(vsmlrt.plugins_path, "libvstrt.so"))

# TensorRT engines are compiled on first use for this exact model + resolution
# + GPU, which takes a minute or so; keep them out of the read-only nix store.
engine_dir = os.path.join(
    os.getenv("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "vsmlrt"
)
os.makedirs(engine_dir, exist_ok=True)


def sc_detect(clip, threshold=0.15):
    """Tag frames preceding a cut so RIFE duplicates instead of interpolating.

    vs-mlrt reads _SceneChangeNext but leaves detection to the caller, and
    VapourSynth R73 no longer bundles misc.SCDetect, so do it with std filters.
    """
    sc_clip = clip.resize.Bicubic(format=vs.GRAY8, matrix_s="709")
    sc_next = (sc_clip[1:] + sc_clip[-1]).std.PlaneStats(sc_clip)

    def set_props(n, f):
        fout = f[0].copy()
        fout.props["_SceneChangeNext"] = int(
            threshold < f[1].props.get("PlaneStatsDiff", 0.0)
        )
        return fout

    return clip.std.ModifyFrame(clips=[clip, sc_next], selector=set_props)


clip = sc_detect(video_in)

# RGBH (half-precision float RGB) is what the fp16 engine wants.
clip = core.resize.Bicubic(clip, format=vs.RGBH, matrix_in_s="709")

clip = RIFE(
    clip,
    multi=2,
    model=RIFEModel.v4_25,
    ensemble=False,
    backend=BackendV2.TRT(
       num_streams=4,
       fp16=True,
       use_cuda_graph=True,
       engine_folder=engine_dir,
    ),
    video_player=True,
    # Implementation 2 pads internally; implementation 1 (the default) rejects
    # any frame size that is not a multiple of 64, i.e. most real video.
    _implementation=2,
)

clip = core.resize.Bicubic(clip, format=vs.YUV420P8, matrix_s="709")
clip.set_output()
