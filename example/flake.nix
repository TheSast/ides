{

  inputs = {
    ides.url = "git+https://git.atagen.co/atagen/ides";
  };

  outputs =
    {
      nixpkgs,
      ides,
      ...
    }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # create an instance of ides to spawn shells from
      mkIdes = import ides {
        # ides needs a pkgs instance to work with in flake mode
        inherit pkgs;

        # all other args here are optional

        # shell function to wrap -
        # could also use pkgs.mkShellNoCC, but override demonstrates
        # more clearly how to change any aspect of the shell
        shell = pkgs.mkShell.override {
          stdenv = pkgs.stdenvNoCC;
        };

        # input for extra modules that provide service options
        # see modules/redis.nix in ides source for example
        modules = [ ];
        # if you want to include a premade service def,
        # use `imports` in the shell instead
      };
    in
    {
      devShells.x86_64-linux.default = mkIdes {
        # import a concrete service definition
        imports = [ ./caddy.nix ];
        # use the options provided by a module
        services.redis = {
          enable = true;
          port = 6889;
          logLevel = "verbose";
        };
        # use normal mkShell options
        nativeBuildInputs = [ pkgs.hello ];
        someEnv = "this";
      };
    };

}
