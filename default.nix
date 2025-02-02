# import stage args
{
  pkgs ? import <nixpkgs>,
  shell ? pkgs.mkShell,
  modules ? [ ],
  ...
}:
# shell creation args
{
  services ? { },
  imports ? [ ],
  ...
}@args:
let
  # filter ides args out
  # for passthrough to mkShell
  shellArgs = builtins.removeAttrs args [
    "services"
    "serviceDefs"
    "imports"
  ];
  # include some premade services
  baseModules = [ ./modules/redis.nix ];
  # eval the config
  eval = pkgs.lib.evalModules {
    modules =
      [
        # ides
        ./ides.nix
        # service config and build params
        (
          _:
          {
            inherit services;
            _buildIdes.shellFn = shell;
            _buildIdes.shellArgs = shellArgs;
          }
        )
      ]
      ++ baseModules
      ++ modules
      ++ imports;

    specialArgs = {
      inherit pkgs;
    };

    class = "ides";
  };
in
eval.config._buildIdes.shell
