#!/bin/sh
#https://stackoverflow.com/questions/22009364/is-there-a-try-catch-command-in-bash

try() {
    [ "${-#*e}" = "$-" ]
    export _SHELL_HAS_OPT_E="$?"
    set +e
}

catch() {
    export _SHELL_EXCEPTION="$?"
    [ "$_SHELL_HAS_OPT_E" = "0" ] && set +e || set -e
    return $_SHELL_EXCEPTION
}

throw() { exit $1; }
throwErrors() { set -e; }
ignoreErrors() { set +e; }

# Use example
: << 'EOC'
#!/bin/sh
export AnException=100
export AnotherException=101

executeCommandThatFailsForSure() { false; }
executeCommand1ThatFailsForSure() { false; }
executeCommand2ThatFailsForSure() { echo "expected error"; }
executeCommand3ThatFailsForSure() { false; }
executeCommandThatMightFail() {
    local N="$(od -vAn -N4 -tu4 < /dev/urandom | tr -d ' ')"
    [ $(($N & 0x1)) -eq 0 ]
}

# start with a try
try
(   # open a subshell !!!
    set -vx
    echo "do something"
    [ 0 -ge 1 ] && throw $AnException

    echo "do something more"
    executeCommandThatMightFail || throw $AnotherException

    throwErrors # automaticatly end the try block, if command-result is non-null
    echo "now on to something completely different"
    executeCommandThatMightFail

    echo "it's a wonder we came so far"
    executeCommandThatFailsForSure || true # ignore a single failing command

    ignoreErrors # ignore failures of commands until further notice
    executeCommand1ThatFailsForSure
    result="$(executeCommand2ThatFailsForSure)"
    [ "$result" != "expected error" ] && throw $AnException # ok, if it's not an expected error, we want to bail out!
    executeCommand3ThatFailsForSure

    echo "finished"
)
# directly after closing the subshell you need to connect a group to the catch using ||
catch || {
    # now you can handle
    case $_SHELL_EXCEPTION in
        $AnException)
            echo "AnException was thrown ($_SHELL_EXCEPTION)"
        ;;
        $AnotherException)
            echo "AnotherException was thrown ($_SHELL_EXCEPTION)"
        ;;
        *)
            echo "An unexpected exception was thrown ($_SHELL_EXCEPTION)"
            throw $_SHELL_EXCEPTION # you can rethrow the "exception" causing the script to exit if not caught
        ;;
    esac
}
EOC
