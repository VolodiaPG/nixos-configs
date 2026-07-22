import vapoursynth as vs
from vsrife import rife
core = vs.core

# 1. Setup the clip (standard mpv-vapoursynth boilerplate)
clip = video_in

# 2. Convert to RGBH (Half-precision FP16)
# This is vital for performance on RTX cards and uses less VRAM
clip = core.resize.Bicubic(clip, format=vs.RGBH, matrix_in_s="709")

# 3. Apply RIFE with Real-Time optimizations
clip = rife(
    clip,
    model="4.25",
    trt=True,
    auto_download=True, # Shouldn't be enabled if using the nix package vsrife
    factor_num=2,
    sc=True                  # Scene change detection
)

# 4. Convert back to YUV for mpv display
clip = core.resize.Bicubic(clip, format=vs.YUV420P10, matrix_s="709")

clip.set_output()
