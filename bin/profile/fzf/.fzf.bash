# Setup fzf
# ---------
FZF_DIR="$RC_DIR/rbin/fzf"
if [[ ! "$PATH" == *"$FZF_DIR"/bin* ]]; then
  export PATH="${PATH:+${PATH}:}$FZF_DIR/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$FZF_DIR/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "$FZF_DIR/shell/key-bindings.bash"
