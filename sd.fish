# Completions for the custom Script Directory (sd) script

# These are based on the contents of the Script Directory, so we're reading info from the files.
# The description is taken either from the first line of the file $cmd.help,
# or the first non-shebang comment in the $cmd file.

# Also note, completions are loaded at fish startup, not dynamically, so you need to reload fish for changes here to take effect.

# The '-f' on all complete commands is to disable file completions everywhere except for after the full command is written out

# Use $HOME/sd as the default location, otherwise take the value of SD_ROOT
function __sd_root_location
    if set -q SD_ROOT
        echo "$SD_ROOT"
    else
        echo "$HOME/sd"
    end
end

# Create command completions for a subcommand
# Takes a list of all the subcommands seen so far
function __sd_list_subcommand
    # Handles fully nested subcommands
    set -l root_location (__sd_root_location)
    set -l basepath (string join '/' "$root_location" $argv)

    # Total subcommands
    # Used so that we can ignore duplicate commands
    set -l commands
    for file in (ls -d "$basepath"/*)
        set -l cmd (basename $file .help)
        set -l helpfile $cmd.help
        if [ (basename $file) != "$helpfile" ]
            set commands $commands $cmd
        end
    end

    # Setup the check for when to show these commands
    # Basically you need to have seen everything in the path up to this point but not any commands in the current directory.
    # This will cause problems if you have a command with the same name as a directory parent.
    set -l check
    for arg in $argv
        set check (string join ' and ' $check "__fish_seen_subcommand_from $arg;")
    end
    set check (string join ' ' $check "and not __fish_seen_subcommand_from $commands")

    # Loop through the files using their full path names.
    for file in (ls -d "$basepath"/*)
        set -l cmd (basename $file .help)
        set -l helpfile $cmd.help
        if [ (basename $file) = "$helpfile" ]
            # This is the helpfile, use it for the help statement
            set -l help (head -n1 "$file")
            complete -f -c sd -a "$cmd" -d "$help" \
                -n $check
        else if test -d "$file"
            set -l help "$cmd commands"
            __sd_list_subcommand $argv $cmd
            complete -f -c sd -a "$cmd" -d "$help" \
                -n "$check"
        else
            set -l help (sed -nE -e '/^#!/d' -e '/^#/{s/^# *//; p; q;}' "$file")
            if not test -e "$helpfile"
                complete -f -c sd -a "$cmd" -d "$help" \
                    -n "$check"
            end
        end
    end
end

function __sd_list_commands
    # commands is used in the completions to know if we've seen the base commands
    set -l commands

    # Create a list of commands for this directory.
    # The list is used to know when to not show more commands from this directory.
    for file in $argv
        set -l cmd (basename $file .help)
        set -l helpfile $cmd.help
        if [ (basename $file) != "$helpfile" ]
            # Ignore the special commands that take the paths as input.
            if not contains $cmd cat edit help new which
                set commands $commands $cmd
            end
        end
    end
    for file in $argv
        set -l cmd (basename $file .help)
        set -l helpfile $cmd.help
        if [ (basename $file) = "$helpfile" ]
            # This is the helpfile, use it for the help statement
            set -l help (head -n1 "$file")
            complete -f -c sd -a "$cmd" -d "$help" \
                -n "not __fish_seen_subcommand_from $commands"
        else if test -d "$file"
            # Directory, start recursing into subcommands
            set -l help "$cmd commands"
            __sd_list_subcommand $cmd
            complete -f -c sd -a "$cmd" -d "$help" \
                -n "not __fish_seen_subcommand_from $commands"
        else
            # Script
            # Pull the help test from the first non-shebang commented line.
            set -l help (sed -nE -e '/^#!/d' -e '/^#/{s/^# *//; p; q;}' "$file")
            if not test -e "$helpfile"
                complete -f -c sd -a "$cmd" -d "$help" \
                    -n "not __fish_seen_subcommand_from $commands"
            end
        end
    end
end

set -l root_location (__sd_root_location)
__sd_list_commands "$root_location"/*

