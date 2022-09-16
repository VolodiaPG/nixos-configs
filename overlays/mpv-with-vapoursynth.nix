self: super:
{
  #  mpv = (pkgs.mpv-unwrapped.override {
  #     vapoursynthSupport = true;
  #     vapoursynth = pkgs.vapoursynth;
  #   }).overrideAttrs (old: rec {
  #     wafConfigureFlags = old.wafConfigureFlags ++ [ "--enable-vapoursynth" ];
  #   });
  # mpv-unwrapped = with super; pkgs.mpv-unwrapped.override { vapoursynthSupport = true; };
  mpv-unwrapped = with super; (pkgs.mpv-unwrapped.override {
    vapoursynthSupport = true;
    vapoursynth = pkgs.vapoursynth;
  }).overrideAttrs (old: rec {
    wafConfigureFlags = old.wafConfigureFlags ++ [ "--enable-vapoursynth" ];
  });
  mpv = with super; pkgs.wrapMpv mpv-unwrapped { youtubeSupport = true; };
}
