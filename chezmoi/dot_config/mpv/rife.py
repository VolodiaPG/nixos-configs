import vapoursynth as vs
import os
from vsrife import rife
core = vs.core
core.num_threads = 8

cache_dir = os.path.join(os.getenv("XDG_CACHE_HOME", "~/.cache"), "vsrife")

os.makedirs(cache_dir, exist_ok=True)

# 1. Setup the clip (standard mpv-vapoursynth boilerplate)
clip = video_in

# 2. Detect true input FPS. mpv-vapoursynth's video_in often lacks fps_num/fps_den
# but exposes _FPSNum/_FPSDen frame props from the container.
fps_num = int(container_fps * 1e8)
fps_den = int(1e8)

# Stamp the detected rate onto the clip so rife() can compute the multiplier.
clip = core.std.AssumeFPS(clip, fpsnum=fps_num, fpsden=fps_den)

# 3. Convert to RGBH (Half-precision FP16)
# This is vital for performance on RTX cards and uses less VRAM
clip = core.resize.Bicubic(clip, format=vs.RGBH, matrix_in_s="709")

# 4. Apply RIFE with Real-Time optimizations
clip = rife(
    clip,
    model="4.25",
    trt=True,
    auto_download=False, # Shouldn't be enabled if using the nix package vsrife
    fps_num=60,
    fps_den=1,
    sc=True,                 # Scene change detection
    trt_cache_dir=cache_dir,  # Nix store is read-only
)

# 4. Convert back to YUV for mpv display
clip = core.resize.Bicubic(clip, format=vs.YUV420P10, matrix_s="709")

clip.set_output()
