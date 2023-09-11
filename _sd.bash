# vim:ft=bash

function _sd_completion {
    if [ ! -v SD_ROOT ]; then
        return 0
    fi

    script_dir=`realpath "$SD_ROOT"`
    script_full="$script_dir"
    is_parse_flags=1

    for word in ${COMP_WORDS[@]:1}; do
        if [ "$word" == "--really" ]; then
            is_parse_flags=0
        fi
        if [ -d "$script_dir/$word" ]; then
            script_dir="$script_dir/$word"
        fi
        script_full="$script_full/$word"
    done

    COMPREPLY=($({
        if [ ! -f "$script_full" ]; then
            ls -1 "$script_dir" 2> /dev/null | while read line; do
                item_path="$script_dir/$line"
                if [[ -d "$item_path" || -f "$item_path" && -x "$item_path" ]]; then
                    basename "$item_path"
                fi
            done
        fi
        if [ "$is_parse_flags" == 1 ]; then
            echo --help
            echo --cat
            echo --which
            echo --edit
            echo --really
            echo --new
        fi
    } | grep "^${COMP_WORDS[-1]}"))
}
complete -F _sd_completion sd
