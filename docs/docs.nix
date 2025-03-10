with import <nixpkgs> { };
{ ... }:
let
  eval = lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      ../lib/ides.nix
      ../modules
    ];
  };
  optionsDoc = nixosOptionsDoc {
    inherit (eval) options;

    transformOptions =
      opt:
      opt
      // {
        # Clean up declaration sites to not refer to the NixOS source tree.
        declarations =
          let
            devDir = toString /home/bolt/code/ides;
            inherit (lib) hasPrefix removePrefix;
          in
          map (
            decl:
            if hasPrefix (toString devDir) (toString decl) then
              let
                subpath = removePrefix "/" (removePrefix (toString devDir) (toString decl));
              in
              {
                url = "https://git.atagen.co/atagen/ides/${subpath}";
                name = subpath;
              }
            else
              decl
          ) opt.declarations;
      };
  };
in
runCommand "docs.md" { } ''
  cat ${optionsDoc.optionsCommonMark} > $out
''
