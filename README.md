# ides
## idempotent devshell ephemeral services

ides provides automated, idempotent launching of ephemeral services

in your devshell,

right here, right now.


## what ?

### it's automatic
 - ides will instantly launch all your declared services,
   as soon as you enter the..

### devshell
 - works just like regular mkShell
 - full support for `shell.nix`, `flake.nix`, and `direnv`

### it's ephemeral
 - ides packages and configs are present only in the nix store
 - once shut down all traces effectively disappear

### they're idempotent
 - ides services cah only ever run one (1) instance of any package+config combination
 - no matter how many times the devshell is opened or the launch command invoked

### they're services
 - ides runs on systemd user services - no additional process manager needed


## the bottom line
your dev environment now reproducibly includes your service dependencies!


## how ?
- bring ides into your nix expression (flake input/fetchGit)
- import it
  - optionally provide a `pkgs` instance, mkShell-like function, or ides modules
- use ides like a normal `mkShell`, but with *spicy extras*
- make sure you run `et-tu` before you log out!

here's how:

### classic nix(tm) ([shell.nix](example/shell.nix))
```nix
let
  pkgs = import <nixpkgs> { };

  ides = fetchGit {
    url = "https://git.atagen.co/atagen/ides";
  };

  mkIdes = import ides {
    # optional instantiation args
    inherit pkgs;
    shell = pkgs.mkShell.override {
      stdenv = pkgs.stdenvNoCC;
    };
    modules = [ ];
  };
in
mkIdes {
  # ides-specific options
  imports = [ ./caddy.nix ];
  services.redis = {
    enable = true;
    port = 6889;
    logLevel = "verbose";
  };
  # regular mkShell options
  nativeBuildInputs = [ pkgs.hello ];
  someEnv = "this";
}
```

### flake enjoyers ([flake.nix](example/flake.nix))
```nix
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
      mkIdes = import ides {
        inherit pkgs;
        shell = pkgs.mkShell.override {
          stdenv = pkgs.stdenvNoCC;
        };
        modules = [ ];
      };
    in
    {
      devShells.x86_64-linux.default = mkIdes {
        imports = [ ./caddy.nix ];
        services.redis = {
          enable = true;
          port = 6889;
          logLevel = "verbose";
        };
        nativeBuildInputs = [ pkgs.hello ];
        someEnv = "this";
      };
    };
}
```

### concrete service definition ([caddy.nix](example/caddy.nix))
```nix
{ pkgs, ... }:
{
  # as simple as possible
  serviceDefs.caddy = {
    pkg = pkgs.caddy;
    # ides injects the config path whereever %CFG% is used in `args`
    args = "run -c %CFG% --adapter caddyfile";
    config.text = ''
      http://*:8888 {
      	respond "hello"
      }
    '';
  };
}
```
here, we use a simple plaintext config, but ides also supports converting
attribute sets into the following formats (via `config.content` & `config.format`):
- `json`
- `yaml`
- `toml`
- `ini`
- `xml`
- `php`
- `java`

### writing a service module
see [the provided redis module](modules/redis.nix) for an example

### more detail
for fully commented examples, see [here](example)

### cli
in case you need manual control, an ides shell provides commands:
- `ides`: raise the service set manually
- `et-tu`: shut down the service set
- `restart`: do both of the above in succession

### documentation
see [module docs](docs/docs.md)

