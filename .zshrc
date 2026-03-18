# ────────────────────────────────────────────────────────────
#  Oh My Zsh
# ────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

# ZSH_THEME disabled — using Starship instead
# ZSH_THEME="robbyrussell"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

# Load zsh-completions
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

source $ZSH/oh-my-zsh.sh

# ────────────────────────────────────────────────────────────
#  PATH
# ────────────────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

# ────────────────────────────────────────────────────────────
#  True Color (critical for Gruvbox in tmux + Neovim)
# ────────────────────────────────────────────────────────────
export COLORTERM="truecolor"
export TERM="xterm-256color"

# ────────────────────────────────────────────────────────────
#  History
# ────────────────────────────────────────────────────────────
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ────────────────────────────────────────────────────────────
#  Editor
# ────────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"

# ────────────────────────────────────────────────────────────
#  GPG (required for signed git commits + Mason package verify)
# ────────────────────────────────────────────────────────────
export GPG_TTY=$(tty)

# ────────────────────────────────────────────────────────────
#  bat — Gruvbox theme
# ────────────────────────────────────────────────────────────
export BAT_THEME="gruvbox-dark"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ────────────────────────────────────────────────────────────
#  fzf
# ────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'bat --color=always {}'"

[ -f "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ] && \
  source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
[ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ] && \
  source "$(brew --prefix)/opt/fzf/shell/completion.zsh"

# ────────────────────────────────────────────────────────────
#  Aliases — navigation
# ────────────────────────────────────────────────────────────
alias v="nvim"
alias vi="nvim"
alias vim="nvim"
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first"
alias lt="eza --tree --icons --level=2"
alias cat="bat --style=plain"
alias grep="rg"
alias find="fd"

# ────────────────────────────────────────────────────────────
#  Aliases — git
# ────────────────────────────────────────────────────────────
alias gs="git status"
alias gc="git commit"
alias ga="git add ."
alias gp="git push"
alias gl="git pull"
alias lg="lazygit"

# ────────────────────────────────────────────────────────────
#  Aliases — tmux
# ────────────────────────────────────────────────────────────
alias t="tmux"
alias ta="tmux attach"
alias tn="tmux new -s"
alias tl="tmux list-sessions"
alias tk="tmux kill-session -t"

# ────────────────────────────────────────────────────────────
#  Aliases — Docker
# ────────────────────────────────────────────────────────────
alias ld="lazydocker"

# ────────────────────────────────────────────────────────────
#  Aliases — Python / uv
# ────────────────────────────────────────────────────────────
alias py="python3"
alias pip="uv pip"

# ────────────────────────────────────────────────────────────
#  Tool init  (order matters — mise first, then prompt, then zoxide)
# ────────────────────────────────────────────────────────────

# Mise — runtime version manager
eval "$(mise activate zsh)"

# Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# zoxide — smarter cd
eval "$(zoxide init zsh)"

# Starship prompt (single init — duplicate removed)
eval "$(starship init zsh)"
alias cl="clear"
