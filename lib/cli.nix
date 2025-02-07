{
  foldlAttrs,
  writeShellScriptBin,
  works,
}:
let
  runAll = foldlAttrs (
    acc: name: works:
    acc + "${works.runner}/bin/run\n"
  ) "" works;
  runFns = foldlAttrs (
    acc: name: works:
    acc
    + ''
      function run-${name}() {
        ${works.runner}/bin/run
      }
    ''
  ) "" works;
  cleanAll = foldlAttrs (
    acc: name: works:
    acc + "${works.cleaner}/bin/clean\n"
  ) "" works;
  cleanFns = foldlAttrs (
    acc: name: works:
    acc
    + ''
      function clean-${name}() {
        ${works.cleaner}/bin/clean
      }
    ''
  ) "" works;
  names = foldlAttrs (
    acc: name: _:
    acc ++ [ name ]
  ) [ ] works;
  help = ''
    [ides]: use "ides [action] [target]" to control services.
    actions: 
      start             synonyms: run r       
      - start a service

      stop              synonyms: s clean et-tu
      - stop a service

      restart           synonyms: qq
      - stop and then restart all services

      targets           synonyms: t
      - print a list of available targets

      help
      - print this helpful information

    target names are the same as the attribute used to define a service.
    an empty target will execute the action on all available services.

    current targets:
  '';
in
writeShellScriptBin "ides" ''
  targets=(${builtins.concatStringsSep " " names})

  function print-help() {
    printf '${help}'
    list-targets
  }

  function list-targets() {
    echo ''${targets[@]}
  }

  function check-target() {
    found=1
    for target in "''${targets[@]}"; do
      if [ "$1" == "$target" ]; then
        found=0
        break
      fi
    done
    printf $found
  }

  ${runFns}

  function run-all() {
    ${runAll}
  }

  ${cleanFns}

  function clean-all() {
    ${cleanAll}
  }

  function action() {
    action=$1
    if [[ $# -gt 1 ]]; then
      shift
      for service in "$@"; do
        if [[ $(check-target $service) -eq 0 ]]; then
          $action-$service
        else
          echo "[ides]: no such target: $service"
        fi
      done
    else
      $action-all
    fi
  }

  case $1 in 
    start|run|r)
      shift
      action run $@
    ;;
    clean|stop|et-tu|s)
      shift
      action clean $@
    ;;
    restart|qq)
      clean-all
      run-all
    ;;
    targets|t)
      list-targets
    ;;
    -h|h|help|*)
      print-help
    ;;
  esac
''
