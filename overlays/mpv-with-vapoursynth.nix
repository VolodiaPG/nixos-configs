self: super:
{
  mpv-unwrapped = with super; pkgs.mpv-unwrapped.override { vapoursynthSupport = true; };
  mpv = with super; pkgs.wrapMpv mpv-unwrapped { youtubeSupport = true; };
}
