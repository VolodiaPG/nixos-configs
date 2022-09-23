{ stdenv
, bcc
, linuxHeaders
, lib
, fetchFromGitHub
, rustPlatform
, ...
}:

rustPlatform.buildRustPackage rec {
  name = "system76-scheduler-${version}";
  version = "93b7a24";

  src = fetchFromGitHub {
    owner = "volodiapg";
    repo = "system76-scheduler";
    rev = "${version}";
    sha256 = "sha256-/JgIRJFoQsFXE7mu2hkjyNDePYrbI1JIP7iwNKPSsAM=";
  };

  cargoSha256 = "sha256-IKKBNUMCvyDxnTAHrEZ0naC+cnMe75DDNs7ESu538aY=";
  
  nativeBuildInputs = [ bcc ];

  EXECSNOOP_PATH = "${bcc}/tools/execsnoop";

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
