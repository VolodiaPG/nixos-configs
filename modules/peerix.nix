_: {
  config.nixos.peerix =
    {
      lib,
      ...
    }:
    with lib;
    {
      options.services.peerix.extraHosts = mkOption {
        description = "Hosts to consider";
        type = types.listOf types.str;
        default = [
          "asus"
          "msi"
          "dell"
        ];
      };

      config = {
        users = {
          users.peerix = {
            isSystemUser = true;
            group = "peerix";
          };
          groups.peerix = { };
        };
      };
    };
}
