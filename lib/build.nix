{
  pkgs,
  config,
  ...
}:
{
  config =
    {
      # validate and complete the service configurations
      _buildIdes.finalServices = builtins.mapAttrs (
        name:
        {
          setup ? "",
          cmd,
          path,
          socket,
          timer,
        }:
        let
          # config hash for unique service names
          cfgHash = builtins.hashString "sha256" cmd;
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
            sdArgs
            setup
            cmd
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
              sdArgs,
              setup, 
              cmd,
            }:
            {
              runner = pkgs.writeShellScriptBin "run" (
                (
                  if setup != ""
                  then
                    # TODO: silence setup output by default with option to show it
                    # sh
                    ''
                      echo "[ides]: setting up ${name}"
                      ${setup}
                    ''
                  else ""
                )
              +
                # sh
                ''
                  echo "[ides]: starting ${name}.."
                  if command -v systemd-run >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
                      systemd-run --user -q -G -u ${unitName} ${sdArgs} ${cmd}
                  else
                      RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
                      PID_FILE="$RUNTIME_DIR/${unitName}.pid"
                      LOG_FILE="$RUNTIME_DIR/${unitName}.log"
                      if [ -f "$PID_FILE" ] && kill -0 "`cat "$PID_FILE"`" 2>/dev/null; then
                          echo "Service ${unitName} already running (PID `cat "$PID_FILE"`)"
                          exit 0
                      fi
                      nohup sh -c "${cmd}" > "$LOG_FILE" 2>&1 &
                      echo "$!" > "$PID_FILE"
                      echo "Started service ${unitName} with PID $!"
                  fi
                ''
              );
              cleaner = pkgs.writeShellScriptBin "clean" ''
                echo "[ides]: stopping ${name}.."
                if command -v systemd-run >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
                    systemctl --user -q stop ${unitName}
                else
                    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
                    PID_FILE="$RUNTIME_DIR/${unitName}.pid"
                    if [ -f "$PID_FILE" ]; then
                        kill "`cat "$PID_FILE"`" 2>/dev/null
                        rm -f "$PID_FILE"
                        echo "Stopped service ${unitName}"
                    else
                        echo "Service ${unitName} not running"
                    fi
                fi
              '';
              status = pkgs.writeShellScriptBin "status" ''
                if command -v systemd-run >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
                    systemctl --user -q status ${unitName}
                else
                    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
                    PID_FILE="$RUNTIME_DIR/${unitName}.pid"
                    LOG_FILE="$RUNTIME_DIR/${unitName}.log"
                    if [ -f "$PID_FILE" ] && kill -0 "`cat "$PID_FILE"`" 2>/dev/null; then
                        echo "Service ${unitName} is running (PID `cat "$PID_FILE"`)"
                        echo "Logs available at $LOG_FILE "
                    else
                        echo "Service ${unitName} is not running"
                    fi
                fi
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
          # shell id is based on the services config
          shellId = builtins.hashString "sha256" (builtins.toJSON config._buildIdes.finalServices);
          monitor = import ./monitor.nix {
            inherit (pkgs) writeShellScriptBin;
            inherit shellId;
            cli = pkgs.lib.getExe cli;
            socat = pkgs.lib.getExe pkgs.socat;
            # TODO make this timeout more lenient?
            timeout = if (pkgs.lib.typeOf config.monitor == "int") then config.monitor else 20;
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
                  monitorRun =
                    let
                      inherit (pkgs.lib) getExe;
                    in
                    if config.monitor then
                      ''
                        systemd-run --user -q -G -u ides-${shellId}-monitor ${getExe monitor.daemon} $PWD
                        ${getExe monitor.client} $$
                      ''
                    else
                      "";
                in
                (shellArgs.shellHook or "")
                + ''
                  printf '[ides]: use "ides [action] [target]" to control services. type "ides help" to find out more.\n'
                  export IDES_CTL="/run/user/$(id -u)/ides-${shellId}.sock"
                ''
                + autoRun
                + monitorRun;
            };
        in
        # TODO make this optionally return the shell components to allow composability with other dev shell solutions
        config._buildIdes.shellFn final;
    };

}
