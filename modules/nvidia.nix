_: {
  config.nixos.nvidia =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      nixpkgs.config = {
        cudaSupport = true;
        allowUnfree = true;
        nvidia.acceptLicense = true;
        allowUnsupportedSystem = false;
      };

      services.xserver.videoDrivers = [ "nvidia" ];
      services.xserver.enable = lib.mkDefault false;

      virtualisation.docker = {
        daemon.settings.features.cdi = true;
      };
      hardware = {
        nvidia-container-toolkit.enable = true;
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-compute-runtime
            intel-media-driver
            intel-vaapi-driver
            libva-vdpau-driver
            libvdpau-va-gl
            mesa
            nvidia-vaapi-driver
            nv-codec-headers-12
          ];
        };
        nvidia = {
          package = config.boot.kernelPackages.nvidiaPackages.production;
          open = true;
          modesetting.enable = true;
          prime.offload.enable = false;
          nvidiaPersistenced = false;
          nvidiaSettings = true;
          powerManagement.enable = true;
        };
      };

      environment.systemPackages = with pkgs; [ ];
    };
}
