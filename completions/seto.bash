_seto() {
    local cur prev opts longopts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD - 1]}"

    opts="-h -v -r -c -f -s -F"
    longopts="--help --version --region --config --format --background-color --highlight-color --font-color --font-size --font-family --font-weight --font-style --font-variant --font-gravity --font-stretch --font-offset --grid-color --grid-size --grid-selected-color --line-width --selected-line-width --search-keys --function"

    if [[ ${cur} == --* ]]; then
        COMPREPLY=($(compgen -W "${longopts}" -- ${cur}))
        return 0
    fi

    if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
        return 0
    fi
}

complete -F _seto seto
