# autoenvstack - improved version of autoenvfish
# inspired by virtualfish
# inspired by autoenvfish
# inspired by autoenv
echo "loaded here"

# allow overriding of the default autoenvstack file name
if not set -q AUTOENVSTACK_FILE
    set -g AUTOENVSTACK_FILE ".env.fish"
end

# stuff we don't want to touch
set restricted_vars 'status' 'history' 'version' '_' \
    'LINES' 'COLUMNS' 'PWD' 'SHLVL' 'FISH_VERSION' 'umask' 'argv' \
    'HOME' 'USER' 'CMD_DURATION' 'CURRENT_STACK' \
    'fish_pid' 'hostname' 'fish_private_mode' 'pipestatus'

set old_prefix autoenv_old_


# Automatic env loading when the current working dir changes
function _autoenvstack --on-variable PWD
    if status --is-command-substitution # doesn't work with 'or', inexplicably
        return
    end

    # find an autoenv file, checking up the directory tree until we find
    # such a file (or nothing)
    set -l envdir $PWD
    while test ! "$envdir" = "" -a ! -f "$envdir/$AUTOENVSTACK_FILE"
        # this strips the last path component from the path.
        set envdir (echo "$envdir" | sed 's|/[^/]*$||')
    end

    set -l current_dir $PWD
    set -l new_stack
    while test ! "$current_dir" = ""
        if test -f "$current_dir/$AUTOENVSTACK_FILE"
            set new_stack $current_dir $new_stack
        end
        # this strips the last path component from the path.
        set current_dir (echo "$current_dir" | sed 's|/[^/]*$||')
    end

    _autoenvstack_switch_to_new_stack $new_stack

    set -g CURRENT_STACK $new_stack

end

function _autoenvstack_switch_to_new_stack
    # we assume that old and new stacks may start with a common part
    # that should be ignored

    # _autoenvstack_switch_to_new_stack implements essentually the following:
    # (using git notation)
    # for env in ($new_stack..$old_stack)[-1..1]
    #   _autoenvstack_deactivate_env $end
    # end
    # for env in $old_stack..$new_stack
    #   _autoenvstack_activate_env $end
    # end

    set -l new_stack $argv

    if test -n "$CURRENT_STACK"
        for i in (seq (count $CURRENT_STACK) -1 1)
            if contains $CURRENT_STACK[$i] $new_stack
                set new_stack_p (math $i+1)
                break
            end
        end
    end

    if test -n "$new_stack"
        for i in (seq (count $new_stack) -1 1)
            if contains $new_stack[$i] $CURRENT_STACK
                set CURRENT_STACK_p (math $i+1)
                break
            end
        end
    end

    if test -n "$CURRENT_STACK_p"
        if not test "$CURRENT_STACK_p" -gt (count $CURRENT_STACK)
            for env_dir in $CURRENT_STACK[(count $CURRENT_STACK)..$CURRENT_STACK_p]
                _autoenvstack_deactivate_env $env_dir
            end
        end
    else
        if test -n "$CURRENT_STACK"
            for env_dir in $CURRENT_STACK[-1..1]
                _autoenvstack_deactivate_env $env_dir
            end
        end
    end

    if test -n "$new_stack_p"
        if not test "$new_stack_p" -gt (count $new_stack)
            for env_dir in $new_stack[$new_stack_p..(count $new_stack)]
                _autoenvstack_activate_env $env_dir
            end
        end
    else
        if test -n "$new_stack"
            for env_dir in $new_stack
                _autoenvstack_activate_env $env_dir
            end
        end
    end
end


function _autoenvstack_activate_env -a env_dir
    # Save shell variables before sourcing the file
    # Variables are saved into unique namespace
    # The namespace is defined as $old_prefix$env_hash$name
    # where $old_prefix is a fixed string
    # $env_hash - the hash of the full path to the folder with AUTOENVSTACK_FILE
    # $name - variable name

    set -l env_hash (_autoenvstack_hash $env_dir)
    for name in (set -n)
        if not contains $name $restricted_vars
            set -g $old_prefix$env_hash$name $$name
        end
    end

    source $env_dir/$AUTOENVSTACK_FILE
end

function _autoenvstack_deactivate_env -a env_dir
    # Restore variables from previously saved namespace

    set -l env_hash (_autoenvstack_hash $env_dir)

    set -l var_names (set -n | grep -v "^$old_prefix$env_hash")
    set -l old_var_names (set -n | grep "^$old_prefix$env_hash" | sed "s|^$old_prefix$env_hash||")

    for var_name in $old_var_names
        set -l old_var_name $old_prefix$env_hash$var_name
        # The tricky part here is not to remove currently active var,
        # but to replace it with new value. Otherwise the export flag is lost.
        set $var_name $$old_var_name
        # We're about to leave the environment, have to clean up the vars from
        # the namespace of environment we're leaving
        set -e $old_var_name
    end

    # Lastly, remove also vars that have been added in the env we're deactivating.
    # To find out which ones to remove we do simple math set difference
    # first, by removing the set of restored vars from the set of currently active vars
    # second, by leaving out the set of restricted vars
    # in can be done with `contains` but it's way more slower
    for name in (comm -23 (echo $var_names | tr ' ' '\n' | sort | psub) \
        (cat (echo $old_var_names | tr ' ' '\n' | sort | psub) \
            (echo $restricted_vars | tr ' ' '\n' | sort | psub) | sort | psub))
        set -e $name
    end
end

# It can be md5 as well
function _autoenvstack_hash
    echo -ns $argv __ | sed 's|[^a-zA-Z0-9_]|_|g'
end

# Run on startup in case fish is launched inside a directory with $AUTOENVSTACK_FILE
# Fixes #3
_autoenvstack
