# import vapoursynth as vs
# core = vs.core

# # core.std.LoadPlugin("@rife@vapoursynth/librife.so")

# clip = video_in

# clip = core.resize.Bicubic(clip, format=vs.RGBS, matrix_in_s='709')
# clip = core.rife.RIFE(clip)
# clip = core.resize.Bicubic(clip, format=vs.YUV420P8, matrix_s='709')

# clip.set_output()
import sys
print('@vsrife@')
sys.path.append('@vsrife@')

from vsrife import RIFE
import vapoursynth as vs
core = vs.core

# core.std.LoadPlugin(path='/usr/lib/x86_64-linux-gnu/libffms2.so')
# clip = core.ffms2.Source(source='test.webm')
# core.std.LoadPlugin("@vsrife@vapoursynth/librife.so")

clip = video_in

clip = vs.core.resize.Bicubic(clip, format=vs.RGBS, matrix_in_s='709')
clip = RIFE(clip)
# clip = core.vs-rife.RIFE(clip)
clip = vs.core.resize.Bicubic(clip, format=vs.YUV420P8, matrix_s="709")

clip.set_output()