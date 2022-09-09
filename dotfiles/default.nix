self: super:
{
  gitconfig = self.callPackage ./gitconfig { };
  mutate = self.callPackage ../pkgs/mutate { };
}
