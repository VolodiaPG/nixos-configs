_default: boot

boot drv="$(hostname)":
    nh os boot . -H {{drv}}

switch drv="$(hostname)":
    nh os switch . -H {{drv}}

dry drv="$(hostname)":
    nh os build . -H {{drv}}

mount hostname:
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount {{justfile_directory()}}/machines/{{hostname}}/disk.nix

dry-darwin:
    nh darwin build . -H Volodias-MacBook-Pro

darwin:
    nh darwin switch . -H Volodias-MacBook-Pro

vm hostname="$(hostname)":
   nix run .#nixosConfigurations.{{ hostname }}.config.system.build.vmWithDisko --  -device virtio-vga-gl \
     -display egl-headless,rendernode=/dev/dri/renderD128 \
     -display spice-app,gl=on
