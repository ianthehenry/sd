# Fish shell completion script for sd (script directory organizer)
# Place this file in ~/.config/fish/completions/ or fish vendor completions directory

# Helper function to check if a path is in the sd directory hierarchy
function __sd_is_in_root
    set -l root_path $SD_ROOT
    if test -z "$root_path"
        set root_path $HOME/sd
    end
    
    test -n "$argv[1]"
    and test "$argv[1]" = "$root_path" -o "**(dirname $argv[1])/**" = "$root_path/**"
end

# Helper function to get the sd root directory
function __sd_get_root
    set -l root_path $SD_ROOT
    if test -z "$root_path"
        set root_path $HOME/sd
    end
    echo $root_path
end

# Extract help text from a script or help file
function __sd_get_help_text
    set -l file $argv[1]
    set -l help_text ""
    
    # Check for .help file
    if test -f "$file.help"
        set help_text (head -n1 "$file.help" 2>/dev/null)
    else if test -f "$file"
        # Extract first comment block from script
        set help_text (sed -nE -e '/^#!/d' -e '/^#/{s/^# *//; p; q;}' "$file" 2>/dev/null)
    end
    
    if test -z "$help_text"
        set help_text (basename "$file")
    end
    
    echo $help_text
end

# Get completion options for the current context
function __sd_get_completions
    set -l current_token (commandline -ct)
    set -l all_tokens (commandline -opc)
    set -l sd_root (__sd_get_root)
    
    # No tokens yet, just show top-level options
    if test (count $all_tokens) -eq 1
        # Show root directory contents and global options
        if test -d "$sd_root"
            # Find all executables and directories in root
            for entry in "$sd_root"/*
                set -l entry_name (basename "$entry")
                set -l help_text ""
                
                if test -d "$entry"
                    set help_text "$entry_name commands"
                    # Check for help file in directory
                    if test -f "$entry/help"
                        set help_text (head -n1 "$entry/help" 2>/dev/null)
                    end
                else if test -x "$entry"
                    set help_text (__sd_get_help_text "$entry")
                else
                    continue
                end
                
                printf "%s\t%s\n" "$entry_name" "$help_text"
            end
        end
        
        # Add special options
        printf "--help\tShow help message\n"
        printf "--list\tList all available commands recursively\n"
        printf "--new\tCreate a new script\n"
        printf "--edit\tEdit an existing script or directory\n"
        printf "--cat\tDisplay script contents\n"
        printf "--which\tShow script path\n"
        printf "--really\tForce execution (bypass safety checks)\n"
        return
    end
    
    # Navigate through the command path to find current context
    set -l target_path "$sd_root"
    set -l arg_index 2  # Start after 'sd' command
    set -l found_target false
    
    # Build the target path by traversing arguments
    while test $arg_index -le (count $all_tokens)
        set -l arg $all_tokens[$arg_index]
        
        # Stop at special options or unknown arguments
        if string match -q -- "--*" "$arg"
            break
        end
        
        # Check if this argument exists in current context
        if test -d "$target_path/$arg" -o -f "$target_path/$arg"
            set target_path "$target_path/$arg"
            set arg_index (math $arg_index + 1)
            set found_target true
        else
            break
        end
    end
    
    # If we're completing a directory, show its contents
    if test -d "$target_path"
        # Check if current token matches any directory content
        for entry in "$target_path"/*
            set -l entry_name (basename "$entry")
            set -l token_prefix ""
            
            # Only show entries that match current token prefix
            if test -n "$current_token"
                if string match -q "{$current_token}*" "$entry_name"
                    set token_prefix "$current_token"
                else
                    continue
                end
            end
            
            set -l help_text ""
            
            if test -d "$entry"
                set help_text "$entry_name commands"
                if test -f "$entry/help"
                    set help_text (head -n1 "$entry/help" 2>/dev/null)
                end
            else if test -x "$entry"
                set help_text (__sd_get_help_text "$entry")
            else
                continue
            end
            
            printf "%s\t%s\n" "$entry_name" "$help_text"
        end
    end
    
    # Add remaining special options if we're at the end of path
    if not test $found_target
        printf "--help\tShow help for this command\n"
        printf "--new\tCreate a new script here\n"
        printf "--edit\tEdit this script or directory\n"
        printf "--cat\tDisplay script contents\n"
        printf "--which\tShow script path\n"
    end
end

# Main completion function
complete -c sd -f -a "(__sd_get_completions)"

# Add descriptions for special options that might be shown directly
complete -c sd -l help -d "Show help message"
complete -c sd -l list -d "List all available commands recursively"
complete -c sd -l new -d "Create a new script"
complete -c sd -l edit -d "Edit an existing script or directory"
complete -c sd -l cat -d "Display script contents"
complete -c sd -l which -d "Show script path"
complete -c sd -l really -d "Force execution (bypass safety checks)"