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
            cmd = mkOption {
              type = str;
              description = "Command to supply to the service.";
              example = "\${pkgs.lib.getExe pkgs.caddy} run -c \${writeText \"config\" cfg.extraConfig} --adapter caddyfile";
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
