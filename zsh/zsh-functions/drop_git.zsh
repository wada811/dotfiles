function drop_git(){
  if (( $# > 0 )); then
    while [[ "$1" == "git" ]];
    do
      shift 1
    done

    \git "$@"
  else
    \git
  fi
}