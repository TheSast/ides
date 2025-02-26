{
  pkgs,
  config,
  ...
}:
{
  config =
    let
      # control flow monstrosity
      branchOnConfig =
        cfg:
        {
          text,
          file,
          content,
          contentFmt,
        }:
        if (cfg.text != "") then
          text
        else if (cfg.file != null) then
          file
        else if (cfg.content != { }) then
          if (cfg.format != null) then
            content
          else if (cfg.formatter != null) then
            contentFmt
          else
            throw "`format` or `formatter` must be set for `content` value ${cfg.content}!"
        else
          "";
    in
    {
      # validate and complete the service configurations
      _buildIdes.finalServices = builtins.mapAttrs (
        name:
        {
          pkg,
          args ? "",
          exec ? "",
          config,
          path,
          socket,
          timer,
        }:
        let
          # make our best effort to use the correct binary
          bin = if (exec == "") then pkgs.lib.getExe pkg else pkgs.lib.getExe' pkg exec;
          # set file extension
          ext =
            if (config.ext != "") || (config.format != null) then "." + (config.ext or config.format) else "";
          # config hash for unique service names
          cfgHash =
            let
              # method to hash a set
              hashContent = builtins.hashString "sha256" (builtins.toJSON config.content);
            in
            branchOnConfig config {
              text = builtins.hashString "sha256" config.text;
              file = builtins.hashFile "sha256" config.file;
              content = hashContent;
              contentFmt = hashContent;
            };

          confFile =
            let
              writers = {
                java = pkgs.formats.javaProperties { };
                json = pkgs.formats.json { };
                yaml = pkgs.formats.yaml { };
                ini = pkgs.formats.ini { };
                toml = pkgs.formats.toml { };
                xml = pkgs.formats.xml { };
                php = pkgs.formats.php { finalVariable = null; };
              };
              # final config name
              confPath = "config-${name}-${cfgHash}${ext}";
            in
            # write out config
            branchOnConfig config {
              text = pkgs.writeText confPath config.text;
              inherit (config) file;
              content = writers.${config.format}.generate confPath config.content;
              contentFmt = config.formatter confPath config.content;
            };
          # template the config path into the launch command
          cfgArgs = builtins.replaceStrings [ "%CFG%" ] [ "${confFile}" ] args;
          # flatten unit options into cli args
          sdArgs =
            let
              inherit (pkgs.lib) foldlAttrs;
              inherit (builtins) concatStringsSep;
              convertToArgList =
                prefix: name: values:
                (map (inner: "${prefix} ${name}=${inner}") values);
              writeArgListFor =
                attrs: prefix:
                if (attrs != { }) then
                  concatStringsSep " " (
                    foldlAttrs (
                      acc: n: v:
                      acc + (convertToArgList prefix n v) + " "
                    ) "" attrs
                  )
                else
                  "";
            in
            concatStringsSep " " [
              (writeArgListFor socket "--socket-property")
              (writeArgListFor path "--path-property")
              (writeArgListFor timer "--timer-property")
            ];
        in
        # transform into attrs that mkWorks expects to receive
        {
          inherit
            bin
            sdArgs
            cfgArgs
            ;
          unitName = "shell-${name}-${cfgHash}";
        }
      ) config.serviceDefs;

      # generate service scripts and create the shell
      _buildIdes.shell =
        let
          # create commands to run and clean up services
          mkWorks =
            name:
            {
              unitName,
              bin,
              cfgArgs,
              sdArgs,
            }:
            {
              runner = pkgs.writeShellScriptBin "run" ''
                echo "[ides]: starting ${name}.."
                systemd-run --user -q -G -u ${unitName} ${sdArgs} ${bin} ${cfgArgs}
              '';
              cleaner = pkgs.writeShellScriptBin "clean" ''
                echo "[ides]: stopping ${name}.."
                systemctl --user -q stop ${unitName}
              '';
              status = pkgs.writeShellScriptBin "status" ''
                systemctl --user -q status ${unitName}
              '';
            };

          works = pkgs.lib.mapAttrs (
            name: serviceConf: mkWorks name serviceConf
          ) config._buildIdes.finalServices;

          # create the ides cli
          cli = import ./cli.nix {
            inherit (pkgs) writeShellScriptBin;
            inherit (pkgs.lib) foldlAttrs;
            inherit works;
          };

          # create the ides shell
          final =
            let
              inherit (config._buildIdes) shellArgs;
            in
            shellArgs
            // {
              nativeBuildInputs = (shellArgs.nativeBuildInputs or [ ]) ++ [
                cli
              ];
              shellHook =
                let
                  autoRun =
                    if config.auto then
                      ''
                        ides run
                      ''
                    else
                      "";
                in
                (shellArgs.shellHook or "")
                + ''
                  printf '[ides]: use "ides [action] [target]" to control services. type "ides help" to find out more.\n'
                ''
                + autoRun;
            };
        in
        config._buildIdes.shellFn final;
    };

}
