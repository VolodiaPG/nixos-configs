{
  common-nix = import ./common-nix.nix;
  auto-upgrade = import ./auto-upgrade.nix;
  builder = import ./builder.nix;
  change-mac = import ./change-mac.nix;
  desktop = import ./desktop.nix;
  elegant-boot = import ./elegant-boot.nix;
  folding-at-home = import ./folding-at-home.nix;
  gaming = import ./gaming.nix;
  hifi = import ./hifi.nix;
  hyperhdr = import ./hyperhdr.nix;
  impermanence = import ./impermanence.nix;
  intel = import ./intel.nix;
  kernel = import ./kernel.nix;
  laptop-server = import ./laptop-server.nix;
  microvms = import ./microvms.nix;
  networking = import ./networking.nix;
  nvidia = import ./nvidia.nix;
  peerix = import ./peerix.nix;
  virt = import ./virt.nix;
  vpn = import ./vpn.nix;
  linux = import ./linux.nix;
}
