_: {
  config.home.desktop =
    {
      lib,
      ...
    }:
    with lib;
    {
      services.ollama = {
        enable = false;
      };
    };
}
