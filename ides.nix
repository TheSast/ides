{
  pkgs,
  config,
  ...
}:
{
  #
  # interface
  #
  options =
    let
      inherit (pkgs) lib;
      inherit (lib) types mkOption;
      serviceConfig =
        with types;
        submodule {
          options = {
            pkg = mkOption {
              type = package;
              description = "Package to use for service.";
              example = "pkgs.caddy";
            };
            exec = mkOption {
              type = str;
              description = "Alternative executable name to use from `pkg`.";
              example = "caddy";
              default = "";
            };
            args = mkOption {
              type = str;
              description = "Arguments to supply to the service binary. Writing %CFG% in this will template to your config location.";
              example = "run -c %CFG% --adapter caddyfile";
              default = "";
            };
            config = mkOption {
              description = "Options for setting the service's configuration.";
              default = { };
              type = submodule {
                options = {
                  text = mkOption {
                    type = str;
                    default = "";
                    description = "Plaintext configuration to use.";
                    example = ''
                      http://*:8080 {
                        respond "hello"
                      }
                    '';
                  };
                  ext = mkOption {
                    type = str;
                    default = "";
                    description = "If your service config requires a file extension, set it here. This overrides `format`'s output path'.";
                    example = "json";
                  };
                  file = mkOption {
                    type = nullOr path;
                    description = "Path to config file. This overrides all other values.";
                    example = ./configs/my-config.ini;
                    default = null;
                  };
                  content = mkOption {
                    type = nullOr attrs;
                    description = "Attributes that define your config values.";
                    default = null;
                    example = {
                      this = "that";
                    };
                  };
                  format = mkOption {
                    type = nullOr (enum [
                      "java"
                      "json"
                      "yaml"
                      "toml"
                      "ini"
                      "xml"
                      "php"
                    ]);
                    description = "Config output format.\nOne of:\n`java json yaml toml ini xml php`.";
                    example = "json";
                    default = null;
                  };
                  formatter = mkOption {
                    type = types.anything;
                    description = "Serialisation/writer function to apply to `content`.\n`format` will auto-apply the correct format if the option value is valid.\nShould take `path: attrs:` and return a storepath.";
                    example = "pkgs.formats.yaml {}.generate";
                    default = null;
                  };
                };
              };
            };
          };
        };
    in
    {
      serviceDefs = mkOption {
        type = types.attrsOf serviceConfig;
        description = "Concrete service definitions, as per submodule options.\nPlease put service-related options into `services` instead, and use this to implement them.";
      };

      # lol https://github.com/NixOS/nixpkgs/issues/293510
      _module.args = lib.mkOption {
        internal = true;
      };

      # for internal use
      _buildIdes = mkOption {
        type = types.attrs;
        internal = true;
      };
    };

  #
  # implementation
  #
  config =
    let
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
            throw "`format` or `formatter` must be set for `content` ${cfg.content}!"
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
        }:
        let
          bin = if (exec == "") then pkgs.lib.getExe pkg else pkgs.lib.getExe' pkg exec;
          ext =
            if (config.ext != "") || (config.format != null) then "." + (config.ext or config.format) else "";
          # we need this to create unit names that correspond to configs
          cfgHash =
            let
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
              confPath = "config-${name}-${cfgHash}${ext}";
            in
            branchOnConfig config {
              text = pkgs.writeText confPath config.text;
              inherit (config) file;
              content = writers.${config.format}.generate confPath config.content;
              contentFmt = config.formatter confPath config.content;
            };

          finalArgs = builtins.replaceStrings [ "%CFG%" ] [ "${confFile}" ] args;
        in
        {
          inherit name bin;
          args = finalArgs;
          unitName = "shell-${name}-${cfgHash}";
        }
      ) config.serviceDefs;

      # generate service scripts and create the shell
      _buildIdes.shell =
        let
          mkWorks =
            {
              name,
              unitName,
              bin,
              args,
            }:
            {
              runner = ''
                echo "[ides]: Starting ${name}.."
                systemd-run --user -G -u ${unitName} ${bin} ${args}
              '';
              cleaner = ''
                echo "[ides]: Stopping ${name}.."
                systemctl --user stop ${unitName}
              '';
            };

          works =
            let
              inherit (pkgs.lib) foldlAttrs;
            in
            foldlAttrs
              (
                acc: name: svc:
                let
                  pair = mkWorks svc;
                in
                {
                  runners = acc.runners + pair.runner;
                  cleaners = acc.cleaners + pair.cleaner;
                }
              )
              {
                runners = "";
                cleaners = "";
              }
              config._buildIdes.finalServices;

          inherit (pkgs) writeShellScriptBin;
          runners = writeShellScriptBin "ides" works.runners;
          cleaners = writeShellScriptBin "et-tu" (
            works.cleaners
            + ''
              systemctl --user reset-failed
            ''
          );
          restart = writeShellScriptBin "restart" "et-tu; ides";

          final =
            let
              shellArgs = config._buildIdes.shellArgs;
            in
            shellArgs
            // {
              nativeBuildInputs = (shellArgs.nativeBuildInputs or [ ]) ++ [
                runners
                cleaners
                restart
              ];
              shellHook =
                (shellArgs.shellHook or "")
                + ''
                  ides
                '';
            };
        in
        config._buildIdes.shellFn final;
    };
}
