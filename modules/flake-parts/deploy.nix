{ self, inputs, ... }:
{
  flake = {
    deploy.nodes = {
      msi = {
        hostname = "msi";
        profiles.system = {
          user = "root";
          sshUser = "volodia";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.msi;
        };
      };
      dell = {
        hostname = "dell";
        profiles.system = {
          user = "root";
          sshUser = "volodia";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dell;
        };
      };
      home-server = {
        hostname = "home-server";
        profiles.system = {
          user = "root";
          sshUser = "volodia";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.home-server;
          fastConnection = true;
        };
      };
    };
  };
}
