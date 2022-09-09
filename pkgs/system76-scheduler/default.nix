{
  # pkgs, stdenv, fetchurl ? import <nixpkgs> {},
  # lib ? pkgs.lib,

  stdenv
, bcc
, just
, linuxHeaders
, lib
, fetchgit
, rustPlatform
, ...
}:

rustPlatform.buildRustPackage rec {
  name = "system76-scheduler-${version}";
  version = "1.2.1";

  src = fetchgit {
    url = "https://github.com/pop-os/system76-scheduler";
    rev = "${version}";
    sha256 = "sha256-Qz4LT+YluuQj9uke2pmFL2X8CYdpOoB70MxjYCyVf+g=";
  };

  nativeBuildInputs = [ just bcc ];

  EXECSNOOP_PATH = "${bcc}/tools/execsnoop";

  cargoSha256 = "sha256-ZbAEeHKALp0S0RwcJOINyp7uueWnXny4Crkl+qEEKyQ=";

  installPhase = ''
    ls -lia target
    ls -lia target/x86_64-unknown-linux-gnu
    ls -lia target/release
    # just sysconfdir="$out/etc" \
    #   bindir="$out/bin" \
    #   libdir="$out/lib" \
    #   target="x86_64-unknown-linux-gnu/release" \
    #   install 
    export confdir="$out/etc"
    export bindir="$out/bin"
    export libdir="$out/lib"
    export target="x86_64-unknown-linux-gnu/release"
    export binary="system76-scheduler"
    export target_bin="$bindir/$binary"

    mkdir $out/bin

    # mkdir -p $confdir/system76-scheduler/assignments \
    #   $confdir/system76-scheduler/exceptions
    # cp data/config.ron $confdir/system76-scheduler/config.ron
    # cp data/assignments.ron $confdir/system76-scheduler/assignments/default.ron
    # cp data/exceptions.ron $confdir/system76-scheduler/exceptions/default.ron
    cp target/$target/$binary $target_bin
    chmod +x  $target-bin
    # cp data/$id.service $libdir/systemd/system/$id.service
    # cp data/$id.conf $confdir/dbus-1/system.d/$id.conf
  '';

  meta = with lib; {
    homepage = https://github.com/pop-os/system76-scheduler/blob/master/justfile;
    description = "System76's userspace scheduler";
    platforms = platforms.linux;
    maintainers = with maintainers; [ volodiapg ];
  };
}
