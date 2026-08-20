import vapoursynth as vs
import os
from vsrife import rife
core = vs.core
core.num_threads = 8

cache_dir = os.path.join(os.getenv("XDG_CACHE_HOME", "~/.cache"), "vsrife")

os.makedirs(cache_dir, exist_ok=True)

clip = video_in

clip = core.resize.Bicubic(clip, format=vs.YUV420P8, matrix_in_s="709")

# Convert to RGBH (Half-precision FP16)
# This is vital for performance on RTX cards and uses less VRAM
clip = core.resize.Bicubic(clip, format=vs.RGBH, matrix_in_s="709")

# 4. Apply RIFE with Real-Time optimizations
clip = rife(
    clip,
    model="4.6",
    trt=True,
    auto_download=False, # Shouldn't be enabled if using the nix package vsrife
    factor_num=3,
    sc=True,                 # Scene change detection
    trt_cache_dir=cache_dir,  # Nix store is read-only
)

# 4. Convert back to YUV for mpv display
clip = core.resize.Bicubic(clip, format=vs.YUV420P8, matrix_s="709")

clip.set_output()
