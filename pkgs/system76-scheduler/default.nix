{
  bcc,
  pkg-config,
  dbus,
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "system76-scheduler";
  version = "unstable-2022-10-05";
  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "system76-scheduler";
    rev = "25a45add4300eab47ceb332b4ec07e1e74e4baaf";
    sha256 = "sha256-eB1Qm+ITlLM51nn7GG42bydO1SQ4ZKM0wgRl8q522vw=";
  };

  cargoPatches = [./ron-rev.diff];
  cargoSha256 = "sha256-EzvJEJlJzCzNEJLCE3U167LkaQHzGthPhIJ6fp0aGk8=";

  nativeBuildInputs = [pkg-config];
  buildInputs = [dbus];

  EXECSNOOP_PATH = "${bcc}/bin/execsnoop";

  postInstall = ''
    install -D -m 0644 data/com.system76.Scheduler.conf $out/etc/dbus-1/system.d/com.system76.Scheduler.conf
    mkdir -p $out/data
    install -D -m 0644 data/*.ron $out/data/
  '';

  meta = with lib; {
    description = "System76 Scheduler";
    homepage = "https://github.com/pop-os/system76-scheduler";
    license = licenses.mpl20;
    platforms = ["i686-linux" "x86_64-linux"];
    maintainers = [maintainers.cmm];
  };
}
