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
