{
  nix = {
    buildMachines = [
      {
        hostName = "dell";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 10;
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        mandatoryFeatures = [];
      }
    ];
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };
}
