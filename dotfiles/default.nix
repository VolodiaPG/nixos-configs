self: super:
{
  gitconfig = self.callPackage ./gitconfig { };
  mpvconfig = self.callPackage ./mpv { };
  mutate = self.callPackage ../pkgs/mutate { };
}
