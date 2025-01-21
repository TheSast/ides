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
