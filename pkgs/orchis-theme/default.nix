{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gitUpdater,
  gnome-themes-extra,
  gtk-engine-murrine,
  jdupes,
  sassc,
  themeVariants ? [], # default: blue
  colorVariants ? [], # default: all
  sizeVariants ? [], # default: standard
  border-radius ? null, # Suggested: 2 < value < 16
  tweaks ? [],
}: let
  pname = "orchis-theme";
in
  lib.checkListOfEnum "${pname}: theme variants" ["default" "purple" "pink" "red" "orange" "yellow" "green" "teal" "grey" "all"] themeVariants
  lib.checkListOfEnum "${pname}: color variants" ["standard" "light" "dark"]
  colorVariants
  lib.checkListOfEnum "${pname}: size variants" ["standard" "compact"]
  sizeVariants
  lib.checkListOfEnum "${pname}: tweaks" ["solid" "compact" "black" "primary" "macos" "submenu" "nord" "dracula"]
  tweaks
  stdenvNoCC.mkDerivation
  rec {
    inherit pname;
    version = "2023-02-26";

    src = fetchFromGitHub {
      owner = "vinceliuice";
      repo = pname;
      rev = version;
      hash = "sha256-Qk5MK8S8rIcwO7Kmze6eAl5qcwnrGsiWbn0WNIPjRnA=";
    };

    nativeBuildInputs = [
      jdupes
      sassc
    ];

    buildInputs = [
      gnome-themes-extra
    ];

    propagatedUserEnvPkgs = [
      gtk-engine-murrine
    ];

    postPatch = ''
      patchShebangs install.sh
    '';

    installPhase = ''
      runHook preInstall

      name= HOME="$TMPDIR" ./install.sh -l \
        ${lib.optionalString (themeVariants != []) "--theme " + builtins.toString themeVariants} \
        ${lib.optionalString (colorVariants != []) "--color " + builtins.toString colorVariants} \
        ${lib.optionalString (sizeVariants != []) "--size " + builtins.toString sizeVariants} \
        ${lib.optionalString (tweaks != []) "--tweaks " + builtins.toString tweaks} \
        ${lib.optionalString (border-radius != null) ("--round " + builtins.toString border-radius + "px")} \
        --dest $out/share/themes

      jdupes --quiet --link-soft --recurse $out/share

      runHook postInstall
    '';

    passthru.updateScript = gitUpdater {};

    meta = with lib; {
      description = "Orchis theme";
      homepage = "https://github.com/vinceliuice/Fluent-gtk-theme";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  }
