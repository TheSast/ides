{
  config,
  pkgs,
  lib,
  ...
}:
{
  # create some options
  options.services.redis =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = lib.mkEnableOption "Enable Redis.";

      bind = mkOption {
        type = with types; listOf str;
        description = "List of IPs to bind to.";
        default = [
          "127.0.0.1"
          "::1"
        ];
      };

      port = mkOption {
        type = types.ints.between 1024 65535;
        description = "Port to bind to.";
        default = 6379;
      };

      socket = mkOption {
        type = with types; nullOr str;
        description = "Unix socket to bind to.";
        default = null;
      };

      socketPerms = mkOption {
        type = with types; nullOr int;
        description = "Permissions for the unix socket.";
        default = null;
      };

      logLevel = mkOption {
        type = types.enum [
          "debug"
          "verbose"
          "notice"
          "warning"
          "nothing"
        ];
        description = "Logging verbosity level.";
        default = "notice";
      };

      databases = mkOption {
        type = types.int;
        description = "Number of databases.";
        default = 16;
      };

      # escape hatch due to redis config being massive
      extraConfig = mkOption {
        type = types.str;
        description = "Additional config directives.";
        default = "";
      };

      name = mkOption {
        type = types.str;
        description = "The name ides uses for this service.";
        default = "redis";
      };
    };

  config.serviceDefs =
    let
      cfg = config.services.redis;
    in
    lib.mkIf cfg.enable {
      # use a customisable name in case the user needs several instances
      "${cfg.name}" = {
        pkg = pkgs.redis;
        # make sure we get the server binary, not cli
        exec = "redis-server";
        args = "%CFG%";
        config = {
          ext = ".conf";
          # these need to be made to match redis config
          # variable names here
          content = {
            inherit (cfg) bind port databases;
            unixsocket = cfg.socket;
            unixsocketperm = cfg.socketPerms;
            loglevel = cfg.logLevel;
          };
          # a formatter needs to take in a set of
          # attrs and write out a file
          formatter =
            let
              # set up serialisation for all types
              serialise = {
                int = builtins.toString;
                bool = b: if b then "yes" else "no";
                string = s: s;
                path = builtins.toString;
                null = _: _;
                list = builtins.concatStringsSep " ";
                float = builtins.toString;
                set = throw "cannot serialise a set in redis format";
                lambda = throw "cannot serialise a lambda, wtf?";
              };
            in
            # create a lambda that can serialise to redis config
            path: attrs:
            let
              text =
                (lib.foldlAttrs (
                  acc: n: v:
                  if (v != null) then acc + "${n} ${serialise.${builtins.typeOf v} v}" + "\n" else acc
                ) "" attrs)
                + cfg.extraConfig;
            in
            (pkgs.writeText path text).outPath;
        };
      };
    };
}
