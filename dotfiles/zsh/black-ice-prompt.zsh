[[ -o interactive ]] || return
export LS_COLORS='rs=0:di=1;34:fi=37:ln=36:so=35:pi=33:ex=32:bd=33:cd=33:su=31:sg=31:tw=1;34:ow=1;34:or=31:mi=31'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
(( $+functions[p10k] )) || return

typeset -g POWERLEVEL9K_USER_FOREGROUND=5
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=4
typeset -g POWERLEVEL9K_MY_LAMBDA_FOREGROUND=4
typeset -g POWERLEVEL9K_DIR_FOREGROUND=6
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=6
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=4
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=4
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=1
for _black_ice_dir in HOME DEFAULT; do
    typeset -g "POWERLEVEL9K_DIR_${_black_ice_dir}_VISUAL_IDENTIFIER_COLOR=4"
    typeset -g "POWERLEVEL9K_DIR_${_black_ice_dir}_FOREGROUND=6"
    typeset -g "POWERLEVEL9K_DIR_${_black_ice_dir}_SHORTENED_FOREGROUND=6"
    typeset -g "POWERLEVEL9K_DIR_${_black_ice_dir}_ANCHOR_FOREGROUND=4"
done
unset _black_ice_dir
if (( $+functions[prompt_my_lambda] )); then
    function prompt_my_lambda() {
        if (( EUID == 0 )); then
            p10k segment -f 3 -t $'\uF120'
        else
            p10k segment -f 4 -t $'\uF303'
        fi
    }
fi
p10k reload
