# ides
## idempotent devshell ephemeral services

ides provides automatic idempotent launching of ephemeral services

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
your dev environment now includes your service dependencies!


## how ?
- bring ides into your nix expression (flake input/fetchGit)
- set it up by invoking its `use` function on your nixpkgs instance
- use `mkShell` like you normally would, but with *spicy extras*
- make sure you run `et-tu` before you log out!

here's how:

### service configuration (caddy.nix)
```nix
{
  pkg = pkgs.caddy;
  args = "run -c %CFG% --adapter caddyfile";
  config = ''
    http://*:8080 {
    	respond "hello"
    }
  '';
}
```
we template the provided config's path as %CFG% in the `args` option.

### classic nix(tm)
```nix
let
  pkgs = import <nixpkgs> {};
  ides = import (fetchGit {
    url = "https://git.atagen.co/atagen/ides";
  });
  mkShell = ides.use pkgs;
in
  mkShell {
    noCC = true;
    services.caddy = import ./caddy.nix;
  }
```

### flake enjoyers
```nix
{
  inputs = {
    ides.url = "git+https://git.atagen.co/atagen/ides";
  };
  outputs = {
    nixpkgs,
    ides,
    ...
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    mkShell = ides.lib.use pkgs;
  in {
    devShells.x86_64-linux.default = mkShell {
      noCC = true;
      services = {
        caddy = import ./caddy.nix;
      };
    };
  };
}
```

### options
- `services: attrset of service configs`: set up your services for ides
- `noCC: bool`: sets whether to use mkShell or mkShellNoCC
- `...`: all other options are passed directly to mkShell as per usual

#### service config attributes
 - `pkg`: the package to launch as a service
 - `args`: the arguments to the service. writing `%CFG%` in this will template to your config location
 - `ext`: in case your service is picky about its file extension, set it here
 - `config`: your service config.

if plaintext isn't your thing, check out pkgs.writers and lib.generators
for ways to generate json, yaml, etc from nix attribute sets.

### cli
in case you need manual control, an ides shell provides commands:
- `ides`: raise the service set manually
- `et-tu`: shut down the service set
- `restart`: do both of the above in succession

## why not reuse (nixpkgs/hm/...) module system ?
ides was originally conceived with this in mind, but in practice,
it is rather difficult to decouple the module systems from the
deployments they are intended to fulfill.

occasional prodding is ongoing, and some activity appears to have
begin in nixpkgs to modularise services, which would allow ides
to take full advantage of the enormous nixos ecosystem.

## acknowledgements
- me
- bald gang
- nixpkgs manual authors
- devenv, for the idea of flake services
