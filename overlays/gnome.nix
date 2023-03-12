_final: prev: {
  gnome = prev.gnome.overrideScope' (_gself: gsuper: {
    mutter = gsuper.mutter.overrideAttrs (_oldAttrs: {
      src = prev.fetchgit {
        url = "https://gitlab.gnome.org/vanvugt/mutter.git";
        rev = "a6f23c151c94912c8fc074facd07b0d6aa70f939"; # triple-buffering-v4-43
        sha256 = "sha256-IqDznMRqEYRp9SVOWtJcShSvnhmkKdSSvJdCEY5MwP0=";
      };
    });
  });
}
