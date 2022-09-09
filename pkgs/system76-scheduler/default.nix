{
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
    mkdir -p $out/{bin,etc/dbus-1/system.d}
    mkdir -p $out/etc/system76-scheduler/{assignments,exceptions}

    install -Dm0644 data/assignments.ron $out/etc/system76-scheduler/assignments/default.ron
    install -Dm0644 data/com.system76.Scheduler.conf $out/etc/dbus-1/system.d/com.system76.Scheduler.conf
    install -Dm0644 data/config.ron $out/etc/system76-scheduler/config.ron
    install -Dm0644 data/exceptions.ron $out/etc/system76-scheduler/exceptions/default.ron
    
    install target/x86_64-unknown-linux-gnu/release/system76-scheduler $out/bin
    chmod +x  $out/bin/*
  '';

  meta = with lib; {
    homepage = https://github.com/pop-os/system76-scheduler/blob/master/justfile;
    description = "System76's userspace scheduler";
    platforms = platforms.linux;
    maintainers = with maintainers; [ volodiapg ];
  };
}
