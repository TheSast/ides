{
  socat,
  writeShellScriptBin,
  shellId,
  cli,
  timeout,
  ...
}:
let
  wait = builtins.toString timeout;
in
{
  daemon = writeShellScriptBin "ides-monitor-${shellId}" ''
    BASE_PATH="$1"
    SOCKET=/run/user/$(id -u)/ides-${shellId}.sock

    # if socket exists, it's already being monitored
    if [ -e "$SOCKET" ]; then
      exit 1
    fi

    PIDS=()

    # loop on socket forever
    while true; do
      # wait to receive a PID
      PID=$(timeout ${wait} ${socat} UNIX-LISTEN:"$SOCKET" -)
      # if received and unique, add to our watch
      if [ "$?" -eq 0 ] && ! [[ "''${PIDS[@]}" =~ $PID ]]; then
        echo adding $PID to watch
        PIDS+=($PID)
        echo pids are now ''${PIDS[@]}
      fi

      # check process statuses
      DEAD=true
      for INDEX in "''${!PIDS[@]}"; do
        REMOVE=false

        # get pid
        CHECK="''${PIDS[$INDEX]}"
        echo checking $CHECK

        # check status
        ALIVE=$(kill -0 "$CHECK" 2>&1 > /dev/null)

        # determine eligibility to act as a service root
        if $ALIVE; then

          CMD=$(cat /proc/$CHECK/comm)
          case "$CMD" in
            # if host is an editor, we don't care about pwd
            code|codium|zed|emacs|intellij*|sublime*)
              DEAD=false
            ;;
            # if it's a shell we really do
            sh|bash|zsh|fish|nu|murex|*)
              DIR=$(readlink /proc/$CHECK/cwd)
              if [[ "$DIR" == "$BASE_PATH"* ]]; then
                DEAD=false
              else
                REMOVE=true
              fi
            ;;
          esac

          echo found $CHECK alive with $CMD in $DIR
          
        else

          echo found $CHECK dead

          REMOVE=true

        fi

        if $REMOVE; then
          echo removing ineligible pid $CHECK 
          unset "PIDS[$INDEX]"
        fi

      done
      
      if "$DEAD"; then
        echo no live pids, breaking
        break
      fi

    done

    # loop has broken, no valid pids left
    echo stopping all!
    ${cli} stop
  '';

  # FIXME if the client finds its parent is an editor process,
  # such as `code`, should it keep walking pids until the final parent?
  client = writeShellScriptBin "ides-notify-${shellId}" ''
    function get-parent() {
      ps --no-header -o ppid:1 $1
    }

    function get-command() {
      cat /proc/$1/comm
    }

    SOCKET=/var/run/user/$(id -u)/ides-${shellId}.sock
    # wait for socket to come up
    while ! [ -e "$SOCKET" ]; do
      sleep 0.5
    done

    # check if our calling shell's parent process is direnv
    PARENT=$(get-parent $1)
    COMM=$(get-command $PARENT)
    TARGET="$1"
    echo found $COMM as parent
    if [[ "$COMM" == "direnv" ]]; then
      # if so, skip up another parent to get the process it is exporting to
      TARGET=$(get-parent $PARENT)
    fi
    # tell monitor about the devshell
    echo "$TARGET" | ${socat} - UNIX-CONNECT:"$SOCKET"
  '';
}
