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
  version = "742fce98a458831eb92d88e83a84fe824a348373";

  src = fetchFromGitHub {
    owner = "volodiapg";
    repo = "system76-scheduler";
    rev = "${version}";
    sha256 = "sha256-EdEPCf6Q5rCR1V81G9eu3WBzkAGQ6AewwlyvQuiB7tY=";
  };

  cargoSha256 = "sha256-sTHlM98xVWqlI9BREVvT4boSBVvBXXa/+a1S7kjZEJQ=";
  
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
