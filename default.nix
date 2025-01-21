{
  use = pkgs: {
    inherit pkgs;
    __functor = self: shell: let
      inherit (pkgs) writeText writeShellScriptBin;
      inherit (pkgs.lib) getExe foldlAttrs;
      inherit (builtins) hashString removeAttrs;

      noCC = shell.noCC or false;

      mkWorks = {
        pkg,
        args ? "",
        config,
        ext ? "",
      }: let
        bin = getExe pkg;

        name = pkg.pname;
        unitName = "shell-${name}-${cfgHash}";

        cfgHash = hashString "sha256" config;
        finalConf = writeText "config-${name}-${cfgHash}${ext}" config;

        finalArgs = builtins.replaceStrings ["%CFG%"] [finalConf.outPath] args;
      in {
        runner = ''
          echo "[ides]: Starting ${name}.."
          systemd-run --user -G -u ${unitName} ${bin} ${finalArgs}
        '';
        cleaner = ''
          echo "[ides]: Stopping ${name}.."
          systemctl --user stop ${unitName}
        '';
      };

      works =
        foldlAttrs (acc: name: svc: let
          pair = mkWorks svc;
        in {
          runners = acc.runners + pair.runner;
          cleaners = acc.cleaners + pair.cleaner;
        }) {
          runners = "";
          cleaners = "";
        } (shell.services or {});

      runners = writeShellScriptBin "ides" works.runners;
      cleaners = writeShellScriptBin "et-tu" (works.cleaners
        + ''
          systemctl --user reset-failed
        '');
      restart = writeShellScriptBin "restart" "et-tu; ides";

      final =
        (removeAttrs shell ["services" "noCC"])
        // {
          nativeBuildInputs = (shell.nativeBuildInputs or []) ++ [runners cleaners restart];
          shellHook = (shell.shellHook or "") + ''
            ides
          '';
        };
    in
      if noCC
      then self.pkgs.mkShellNoCC final
      else self.pkgs.mkShell final;
  };
}
