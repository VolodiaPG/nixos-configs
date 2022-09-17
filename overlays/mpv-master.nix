self: super: {
  # mpv-unwrapped = (super.mpv-unwrapped.overrideAttrs (old: {
  #   version = "git";
  #   src = super.fetchFromGitHub {
  #     owner = "mpv-player";
  #     repo = "mpv";
  #     rev = "ba81e4ed88433b021282ca435c80361418d66999";
  #     sha256 =  "sha256-10y4fNLDqVgfxackx98gD3xetC3dzMVNgE1Gd+7NaZE=";
  #   };
  # })).override { vapoursynthSupport = true; };
  mpv-unwrapped = super.mpv-unwrapped.override { vapoursynthSupport = true; };
  mpv = self.wrapMpv self.mpv-unwrapped { youtubeSupport = true; };
}
