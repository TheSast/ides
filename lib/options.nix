{
  pkgs,
  ...
}:
{
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
            socket = mkOption {
              type = attrsOf (listOf str);
              description = "List of socket options for the unit (see `man systemd.socket`) - supplied as a list due to some options allowing duplicates.";
              example = {
                ListenStream = [ "/run/user/1000/myapp.sock" ];
              };
              default = { };
            };
            path = mkOption {
              type = attrsOf (listOf str);
              description = "List of path options for the unit (see `man systemd.path`) - supplied as a list due to some options allowing duplicates.";
              example = {
                PathModified = [ "/some/path" ];
              };
              default = { };
            };
            timer = mkOption {
              type = attrsOf (listOf str);
              description = "List of timer options for the unit (see `man systemd.path`) - supplied as a list due to some options allowing duplicates.";
              example = {
                OnActiveSec = [ 50 ];
              };
              default = { };
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
                    example = "./configs/my-config.ini";
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
        description = "Concrete service definitions, as per submodule options.\nPlease put service-related options into `options.services` instead, and use this to implement those options.";
      };

      auto = mkOption {
        type = types.bool;
        description = "Whether to autostart ides services at devshell instantiation.";
        default = true;
      };

      monitor = mkOption {
        type = types.either types.bool types.int;
        description = "Enable, or set timeout period for, monitoring devshell activity and automatically destroying services after (experimental).";
        default = true;
      };

      # to prevent generating docs for this option; see https://github.com/NixOS/nixpkgs/issues/293510
      _module.args = mkOption {
        internal = true;
      };

      # for internal use
      _buildIdes = mkOption {
        type = types.attrs;
        internal = true;
      };
    };

}
