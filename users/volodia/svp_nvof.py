import vapoursynth as vs
core = vs.core

core.std.LoadPlugin("@svpflow@libsvpflow1_vs64.so")
core.std.LoadPlugin("@svpflow@libsvpflow2_vs64.so")

clip = video_in

smoothfps_params = "{rate:{num:2,den:1,abs:false},algo:21,block:false,cubic:1,mask:{area:25},scene:{mode:0},light:{aspect:0,lights:29,border:107,length:187,cell:5}}"

src_fps     = container_fps if container_fps>0.1 else 29.97
demo_mode   = 0
stereo_type = 0

def interpolate(clip):
# input_um - original frame in 4:2:0
# input_m  - cropped and resized (if needed) frame
# input_m8 - input_m converted to 8-bit
    input_um = clip.resize.Point(format=vs.YUV420P8,dither_type="random")
    input_m = input_um
    input_m8 = input_m

    smooth  = core.svp2.SmoothFps_NVOF(input_m,smoothfps_params,nvof_src=input_m8,src=input_um,fps=src_fps)

    if demo_mode==1:
        return demo(input_m,smooth)
    else:
        return smooth

if stereo_type == 1:
    lf = interpolate(core.std.CropRel(clip,0,(int)(clip.width/2),0,0))
    rf = interpolate(core.std.CropRel(clip,(int)(clip.width/2),0,0,0))
    smooth = core.std.StackHorizontal([lf, rf])
elif stereo_type == 2:
    lf = interpolate(core.std.CropRel(clip,0,0,0,(int)(clip.height/2)))
    rf = interpolate(core.std.CropRel(clip,0,0,(int)(clip.height/2),0))
    smooth = core.std.StackVertical([lf, rf])
else:
    smooth = interpolate(clip)

smooth.set_output()
