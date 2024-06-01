complete -f -c seto

complete -c seto -s h -l help --description "Display help information and quit"
complete -c seto -s v -l version --description "Display version information and quit"

complete -c seto -s r -l region --description "Select region of screen"
complete -c seto -s c -l config --description "Specifies config file" -r
complete -c seto -s f -l format --description "Specifies format of output" -r

complete -c seto -l background-color --description "Set background color" -r
complete -c seto -l filter-color --description "Set color of filter" -r

complete -c seto -l highlight-color --description "Set highlighted color" -r
complete -c seto -l font-color --description "Set font color" -r
complete -c seto -l font-size --description "Set font size" -r
complete -c seto -l font-family --description "Set font family" -r
complete -c seto -l font-weight --description "Set font weight" -r
complete -c seto -l font-style --description "Set font style" -r
complete -c seto -l font-variant --description "Set font variant" -r
complete -c seto -l font-gravity --description "Set font gravity" -r
complete -c seto -l font-stretch --description "Set font stretch" -r
complete -c seto -l font-offset --description "Change position of text on grid" -r

complete -c seto -l grid-color --description "Set color of grid" -r
complete -c seto -l grid-size --description "Set size of each square" -r
complete -c seto -l grid-offset --description "Change default position of grid" -r
complete -c seto -l grid-selected-color --description "Change color of selected position in region mode" -r
complete -c seto -l line-width --description "Set width of grid lines" -r
complete -c seto -l selected-line-width --description "Change line width of selected position in region mode" -r

complete -c seto -s s -l search-keys --description "Set keys used to search" -r
complete -c seto -s F -l function --description "Bind function to a key" -r
