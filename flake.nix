{
  outputs =
    { ... }:
    {
      lib = import ./default.nix;
      templates.default = {
        path = ./example;
        description = "the ides template";
      };
    };
}
