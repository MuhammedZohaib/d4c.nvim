#!/usr/bin/env bash
# =============================================================================
#  d4c — Full Dev Environment Installer
#  Neovim (d4c.nvim) · Zsh + Oh My Zsh · tmux + TPM · Nerd Fonts
#  macOS · Debian/Ubuntu/Kali · Arch · Fedora · WSL
#  github.com/MuhammedZohaib/d4c.nvim
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'
RESET='\033[0m'

step()    { echo -e "\n${MAGENTA}${BOLD}>> $*${RESET}"; }
info()    { echo -e "  ${CYAN}${BOLD}->${RESET} $*"; }
ok()      { echo -e "  ${GREEN}${BOLD}OK${RESET} $*"; }
warn()    { echo -e "  ${YELLOW}${BOLD}!!${RESET}  $*"; }
error()   { echo -e "  ${RED}${BOLD}XX${RESET}  $*" >&2; exit 1; }
has()     { command -v "$1" &>/dev/null; }

BACKUP_TS="$(date +%Y%m%d_%H%M%S)"

bak() {
  [[ -e "$1" ]] \
    && mv "$1" "${1}.bak.${BACKUP_TS}" \
    && warn "Backed up $1 -> ${1}.bak.${BACKUP_TS}" \
    || true
}

# ── Resolve real invoking user (survives sudo) ────────────────────────────────
if   [[ -n "${SUDO_USER:-}" ]];                        then REAL_USER="$SUDO_USER"
elif [[ -n "${USER:-}" ]] && [[ "$USER" != "root" ]];  then REAL_USER="$USER"
else REAL_USER="$(logname 2>/dev/null || whoami)"; fi

REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)"
[[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]] && REAL_HOME="$(eval echo ~"${REAL_USER}")"

export HOME="$REAL_HOME"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${REAL_HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${REAL_HOME}/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${REAL_HOME}/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${REAL_HOME}/.local/state}"

# Drop to real user for commands that must not run as root
run_as() {
  if [[ "$EUID" -eq 0 && "$REAL_USER" != "root" ]]; then
    sudo -u "$REAL_USER" env \
      HOME="$REAL_HOME" \
      XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
      XDG_DATA_HOME="$XDG_DATA_HOME" \
      XDG_CACHE_HOME="$XDG_CACHE_HOME" \
      PATH="$PATH" "$@"
  else
    "$@"
  fi
}

# ── Banner ────────────────────────────────────────────────────────────────────
clear
echo -e "${CYAN}${BOLD}"
echo "  d4c — Full Dev Environment"
echo "  Neovim · Zsh · Oh My Zsh · tmux · Nerd Fonts"
echo "  github.com/MuhammedZohaib/d4c.nvim"
echo -e "${RESET}"
echo ""

if [[ "$EUID" -eq 0 ]]; then
  warn "Running as root. Installing configs to: ${REAL_HOME} (user: ${REAL_USER})"
  read -rp "  Continue? [y/N] " _yn
  [[ "$_yn" =~ ^[Yy]$ ]] || exit 1
fi

info "User: ${REAL_USER}  Home: ${REAL_HOME}"

# ── Detect WSL ────────────────────────────────────────────────────────────────
IS_WSL=false
[[ -n "${WSL_DISTRO_NAME:-}" ]] \
  || grep -qi microsoft /proc/version 2>/dev/null \
  && IS_WSL=true || true

# =============================================================================
# 1. OS + PACKAGE MANAGER
# =============================================================================
step "Detecting OS"

OS=""; PKG_UPDATE=""; PKG_INSTALL=""

case "$(uname -s)" in
  Darwin)
    OS="macos"
    if ! has brew; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    PKG_UPDATE="brew update"
    PKG_INSTALL="brew install"
    ;;
  Linux)
    [[ -f /etc/os-release ]] && . /etc/os-release || true
    case "${ID:-}" in
      debian|ubuntu|kali|linuxmint|pop)
        OS="debian"
        PKG_UPDATE="sudo apt-get update -y"
        PKG_INSTALL="sudo apt-get install -y"
        ;;
      arch|manjaro|endeavouros|garuda)
        OS="arch"
        PKG_UPDATE="sudo pacman -Sy --noconfirm"
        PKG_INSTALL="sudo pacman -S --noconfirm --needed"
        ;;
      fedora|rhel|centos|rocky|alma)
        OS="fedora"
        PKG_UPDATE="sudo dnf check-update -y || true"
        PKG_INSTALL="sudo dnf install -y"
        ;;
      *)
        warn "Unknown distro '${ID:-}' — defaulting to apt"
        OS="debian"
        PKG_UPDATE="sudo apt-get update -y"
        PKG_INSTALL="sudo apt-get install -y"
        ;;
    esac
    ;;
  *) error "Unsupported OS: $(uname -s)" ;;
esac

ok "OS: ${OS} | WSL: ${IS_WSL}"

# =============================================================================
# 2. SYSTEM DEPS
# =============================================================================
step "Installing system dependencies"

eval "$PKG_UPDATE" &>/dev/null || true

case "$OS" in
  macos)
    $PKG_INSTALL git curl wget unzip tar make gcc cmake \
      ripgrep fd node python3 luarocks tmux zsh fontconfig \
      2>/dev/null || warn "Some brew packages failed."
    ;;
  debian)
    $PKG_INSTALL git curl wget unzip tar make gcc g++ cmake \
      ripgrep fd-find nodejs npm \
      python3 python3-pip python3-venv \
      luarocks tmux zsh \
      xclip xsel fontconfig build-essential \
      2>/dev/null || warn "Some apt packages failed."
    if has fdfind && ! has fd; then
      mkdir -p "$REAL_HOME/.local/bin"
      ln -sf "$(which fdfind)" "$REAL_HOME/.local/bin/fd"
      info "Linked fdfind -> fd"
    fi
    ;;
  arch)
    $PKG_INSTALL git curl wget unzip tar make gcc cmake \
      ripgrep fd nodejs npm python python-pip luarocks \
      tmux zsh xclip xsel wl-clipboard fontconfig base-devel \
      2>/dev/null || warn "Some pacman packages failed."
    ;;
  fedora)
    $PKG_INSTALL git curl wget unzip tar make gcc gcc-c++ cmake \
      ripgrep fd-find nodejs npm python3 python3-pip luarocks \
      tmux zsh xclip xsel fontconfig \
      2>/dev/null || warn "Some dnf packages failed."
    ;;
esac

ok "System deps done."

# =============================================================================
# 3. NEOVIM
# =============================================================================
step "Installing Neovim (>= 0.9)"

version_gte() { printf '%s\n%s\n' "$2" "$1" | sort -V -C; }

_need_nvim=true
if has nvim; then
  _ver=$(nvim --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "0.0.0")
  if version_gte "$_ver" "0.9.0" && [[ "$IS_WSL" == "false" ]]; then
    ok "Neovim ${_ver} already installed."
    _need_nvim=false
  else
    warn "WSL detected or version too old (${_ver}) — reinstalling Neovim."
  fi
fi

if [[ "$_need_nvim" == "true" ]]; then
  mkdir -p "$REAL_HOME/.local/bin"
  case "$OS" in
    macos) brew install neovim ;;
    arch)  $PKG_INSTALL neovim ;;
    debian|fedora)
      _appimage="/tmp/nvim.appimage"
      curl -fsSL \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage" \
        -o "$_appimage"
      chmod +x "$_appimage"
      if [[ "$IS_WSL" == "true" ]]; then
        info "WSL: extracting AppImage (no FUSE needed)..."
        rm -rf /tmp/squashfs-root
        cd /tmp && "$_appimage" --appimage-extract &>/dev/null
        rm -rf "$REAL_HOME/.local/nvim"
        mv /tmp/squashfs-root "$REAL_HOME/.local/nvim"
        ln -sf "$REAL_HOME/.local/nvim/AppRun" "$REAL_HOME/.local/bin/nvim"
      else
        cp "$_appimage" "$REAL_HOME/.local/bin/nvim"
      fi
      sudo ln -sf "$REAL_HOME/.local/bin/nvim" /usr/local/bin/nvim 2>/dev/null || true
      rm -f "$_appimage"
      ;;
  esac
  ok "Neovim installed."
fi

# =============================================================================
# 4. WRITE DOTFILES EARLY
#    .zshrc and .tmux.conf are written HERE, before any optional git clones
#    that could fail and exit the script under set -euo pipefail
# =============================================================================

# ── 4a. Write ~/.zshrc ────────────────────────────────────────────────────────
step "Writing ~/.zshrc"
mkdir -p "$REAL_HOME"
bak "$REAL_HOME/.zshrc"

cat > "$REAL_HOME/.zshrc" << 'ZSHRC_END'
# =============================================================================
#  ~/.zshrc — d4c dev environment
#  github.com/MuhammedZohaib/d4c.nvim
# =============================================================================

# Powerlevel10k instant prompt (must stay near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -- Oh My Zsh ----------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git sudo
  colored-man-pages
  command-not-found
  history-substring-search
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  you-should-use
)

source "$ZSH/oh-my-zsh.sh"

# -- Powerlevel10k ------------------------------------------------------------
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# -- PATH ---------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# -- Environment --------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# -- History ------------------------------------------------------------------
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY EXTENDED_HISTORY

# -- Completion ---------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# -- Keybinds -----------------------------------------------------------------
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# -- Navigation ---------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'
alias c='clear'
alias q='exit'

# -- ls (eza > lsd > ls) ------------------------------------------------------
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --git --group-directories-first'
  alias lt='eza --tree --icons -L 2'
elif command -v lsd &>/dev/null; then
  alias ls='lsd --group-dirs first'
  alias ll='lsd -lah --group-dirs first'
else
  alias ls='ls --color=auto'
  alias ll='ls -lAh --color=auto'
fi

# -- Git ----------------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias grb='git rebase'
alias gst='git stash'
alias gstp='git stash pop'
alias lg='lazygit'

# -- Neovim -------------------------------------------------------------------
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias vimrc='nvim ~/.config/nvim'
alias zshrc='nvim ~/.zshrc'
alias tmuxconf='nvim ~/.tmux.conf'

# -- tmux ---------------------------------------------------------------------
alias t='tmux'
alias ta='tmux attach -t'
alias tl='tmux ls'
alias tn='tmux new -s'
alias tk='tmux kill-session -t'
alias td='tmux detach'
alias tka='tmux kill-server'

# -- System -------------------------------------------------------------------
alias reload='source ~/.zshrc && echo "reloaded."'
alias path='echo -e "${PATH//:/\\n}"'
alias ip='curl -s https://ipinfo.io/ip && echo'
alias ports='ss -tulpn'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# -- Dev ----------------------------------------------------------------------
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server 8000'
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias npmg='npm install -g'

# -- fzf ----------------------------------------------------------------------
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
fi

# -- NVM ----------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]]          && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# -- Auto-activate .venv on cd ------------------------------------------------
autoload -Uz add-zsh-hook
_auto_venv() {
  [[ -f "$PWD/.venv/bin/activate" && "$VIRTUAL_ENV" != "$PWD/.venv" ]] \
    && source "$PWD/.venv/bin/activate" || true
}
add-zsh-hook chpwd _auto_venv

# -- WSL ----------------------------------------------------------------------
if grep -qi microsoft /proc/version 2>/dev/null; then
  export DISPLAY="${DISPLAY:-:0}"
  alias pbcopy='clip.exe'
  alias pbpaste='powershell.exe Get-Clipboard'
  alias open='explorer.exe .'
fi
ZSHRC_END

chown "${REAL_USER}:${REAL_USER}" "$REAL_HOME/.zshrc" 2>/dev/null || true
ok "~/.zshrc written."

# ── 4b. Write ~/.tmux.conf ────────────────────────────────────────────────────
step "Writing ~/.tmux.conf"
bak "$REAL_HOME/.tmux.conf"

cat > "$REAL_HOME/.tmux.conf" << 'TMUX_END'
# =============================================================================
#  ~/.tmux.conf — d4c dev environment
#  github.com/MuhammedZohaib/d4c.nvim
#
#  Prefix : Ctrl+A
#  Reload : Prefix + r
#  Splits : Prefix+|  Prefix+-
#  Panes  : Ctrl+H/J/K/L  (Neovim aware)
#  Zoom   : Prefix+z
#  Copy   : v = begin  y = yank  (vi mode)
# =============================================================================

# -- Prefix -------------------------------------------------------------------
unbind C-b
set-option -g prefix C-a
bind-key  C-a send-prefix

# -- Core settings ------------------------------------------------------------
set  -g default-terminal   "tmux-256color"
set  -ag terminal-overrides ",xterm-256color:RGB"
set  -g mouse               on
set  -sg escape-time        0
set  -g history-limit       100000
set  -g base-index          1
setw -g pane-base-index     1
set  -g renumber-windows    on
set  -g set-titles          on
set  -g set-titles-string   "#S | #W"
set  -g focus-events        on
set  -g visual-activity     off
set  -g visual-bell         off
set  -g bell-action         none

# -- Reload config ------------------------------------------------------------
bind r source-file ~/.tmux.conf \; display-message " Config reloaded!"

# -- Splits -------------------------------------------------------------------
unbind '"'
unbind %
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window      -c "#{pane_current_path}"

# -- Pane navigation (Neovim aware) ------------------------------------------
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
  | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?$'"

bind-key -n C-h if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n C-j if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n C-k if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n C-l if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# -- Pane resize --------------------------------------------------------------
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# -- Windows & sessions -------------------------------------------------------
bind -r n next-window
bind -r p previous-window
bind     Tab last-window
bind     W   choose-tree -Zw
bind     z   resize-pane -Z
bind     S   new-session
bind     D   detach-client
bind     X   confirm-before -p "Kill session #S? [y/n]" kill-session

# -- Layouts ------------------------------------------------------------------
bind M-1 select-layout even-horizontal
bind M-2 select-layout even-vertical
bind M-3 select-layout main-horizontal
bind M-4 select-layout tiled

# -- Copy mode (vi) -----------------------------------------------------------
setw -g mode-keys vi
bind Enter copy-mode
bind -T copy-mode-vi v     send -X begin-selection
bind -T copy-mode-vi C-v   send -X rectangle-toggle
bind -T copy-mode-vi V     send -X select-line
bind -T copy-mode-vi Escape send -X cancel

# OS-aware clipboard
if-shell 'uname | grep -q Darwin' {
  bind -T copy-mode-vi y               send -X copy-pipe-and-cancel "pbcopy"
  bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"
} {
  if-shell 'grep -qi microsoft /proc/version 2>/dev/null' {
    bind -T copy-mode-vi y               send -X copy-pipe-and-cancel "clip.exe"
    bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "clip.exe"
  } {
    if-shell 'command -v xclip > /dev/null' {
      bind -T copy-mode-vi y               send -X copy-pipe-and-cancel "xclip -in -selection clipboard"
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "xclip -in -selection clipboard"
    } {
      bind -T copy-mode-vi y               send -X copy-pipe-and-cancel "xsel --clipboard --input"
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "xsel --clipboard --input"
    }
  }
}

# -- Status bar (Catppuccin Mocha) --------------------------------------------
set -g status on
set -g status-interval  5
set -g status-position  bottom
set -g status-justify   left

set -g status-style          "fg=#cdd6f4,bg=#1e1e2e"
set -g status-left-length    50
set -g status-right-length   120

set -g status-left \
  "#[fg=#1e1e2e,bg=#89b4fa,bold] #S \
#[fg=#89b4fa,bg=#313244]\
#[fg=#cdd6f4,bg=#313244] #(whoami) \
#[fg=#313244,bg=#1e1e2e] "

set -g status-right \
  "#[fg=#313244,bg=#1e1e2e]\
#[fg=#cdd6f4,bg=#313244]  #{pane_current_path} \
#[fg=#585b70,bg=#313244]| \
#[fg=#f9e2af,bg=#313244] %H:%M \
#[fg=#585b70,bg=#313244]| \
#[fg=#a6e3a1,bg=#313244] %d %b \
#[fg=#313244,bg=#1e1e2e]"

set -g window-status-format         "#[fg=#585b70,bg=#1e1e2e]  #I #W  "
set -g window-status-current-format "#[fg=#1e1e2e,bg=#89b4fa] #I #W #[fg=#89b4fa,bg=#1e1e2e]"

set -g pane-border-style        "fg=#313244"
set -g pane-active-border-style "fg=#89b4fa"
set -g pane-border-lines        heavy

set -g message-style         "fg=#1e1e2e,bg=#f9e2af,bold"
set -g message-command-style "fg=#1e1e2e,bg=#f5c2e7,bold"

# -- Plugins ------------------------------------------------------------------
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'tmux-plugins/tmux-open'

set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-nvim         'session'
set -g @continuum-restore               'on'
set -g @continuum-save-interval         '10'
set -g @yank_selection_mouse            'clipboard'
set -g @open-S                          'https://duckduckgo.com/?q='

# -- TPM (must be last line) --------------------------------------------------
run '~/.tmux/plugins/tpm/tpm'
TMUX_END

chown "${REAL_USER}:${REAL_USER}" "$REAL_HOME/.tmux.conf" 2>/dev/null || true
ok "~/.tmux.conf written."

# =============================================================================
# 5. OH MY ZSH + PLUGINS + P10K
#    All steps here use || warn — nothing here kills the script
# =============================================================================
step "Installing Oh My Zsh"

OMZ_DIR="$REAL_HOME/.oh-my-zsh"
if [[ -d "$OMZ_DIR" ]]; then
  ok "Oh My Zsh already present."
else
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    run_as sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    2>/dev/null || warn "OMZ install had warnings."
  ok "Oh My Zsh installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-${OMZ_DIR}/custom}"
mkdir -p "${ZSH_CUSTOM}/plugins" "${ZSH_CUSTOM}/themes"

_plugin() {
  local name="$1" url="$2" dest="${ZSH_CUSTOM}/plugins/${1}"
  if [[ -d "$dest" ]]; then
    ok "Plugin already present: ${name}"
  else
    info "Plugin: ${name}..."
    run_as git clone --depth 1 "$url" "$dest" &>/dev/null \
      && ok "Plugin installed: ${name}" \
      || warn "Plugin failed: ${name} (non-fatal)"
  fi
}

_plugin zsh-autosuggestions    https://github.com/zsh-users/zsh-autosuggestions
_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
_plugin zsh-completions         https://github.com/zsh-users/zsh-completions
_plugin you-should-use          https://github.com/MichaelAquilina/zsh-you-should-use

P10K_DIR="${ZSH_CUSTOM}/themes/powerlevel10k"
if [[ -d "$P10K_DIR" ]]; then
  ok "Powerlevel10k already present."
else
  info "Powerlevel10k..."
  run_as git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" &>/dev/null \
    && ok "Powerlevel10k installed." \
    || warn "Powerlevel10k clone failed (non-fatal)."
fi

# =============================================================================
# 6. CHANGE DEFAULT SHELL TO ZSH
# =============================================================================
step "Setting default shell to zsh"

if ! has zsh; then
  $PKG_INSTALL zsh 2>/dev/null || warn "zsh install failed."
fi

_cur_shell="$(basename "${SHELL:-bash}")"
if [[ "$_cur_shell" == "zsh" ]]; then
  ok "Shell is already zsh."
else
  ZSH_BIN="$(which zsh)"
  grep -qxF "$ZSH_BIN" /etc/shells 2>/dev/null \
    || echo "$ZSH_BIN" | sudo tee -a /etc/shells &>/dev/null || true
  sudo chsh -s "$ZSH_BIN" "$REAL_USER" 2>/dev/null \
    || chsh -s "$ZSH_BIN" 2>/dev/null \
    || warn "chsh failed — run: sudo chsh -s \$(which zsh) ${REAL_USER}"
  ok "Default shell → zsh (re-login to apply)."
fi

# =============================================================================
# 7. TMUX + TPM
# =============================================================================
step "Installing tmux + TPM"

if ! has tmux; then
  $PKG_INSTALL tmux 2>/dev/null || warn "tmux install failed."
fi
ok "tmux: $(tmux -V)"

TPM_DIR="$REAL_HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
  ok "TPM already present."
else
  info "Cloning TPM..."
  run_as git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" &>/dev/null \
    && ok "TPM installed." \
    || warn "TPM clone failed — press Ctrl+A+I inside tmux to install manually."
fi

# Install plugins headlessly
if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
  info "Installing tmux plugins..."
  run_as tmux new-session -d -s __d4c_tpm 2>/dev/null || true
  run_as "$TPM_DIR/bin/install_plugins" &>/dev/null \
    && ok "tmux plugins installed." \
    || warn "TPM install had warnings — press Ctrl+A+I to finish."
  run_as tmux kill-session -t __d4c_tpm 2>/dev/null || true
else
  warn "Press Ctrl+A then I inside tmux to install plugins."
fi

# =============================================================================
# 8. NODE + PYTHON TOOLS
# =============================================================================
step "Node.js + Python tools"

info "npm globals..."
sudo npm install -g --quiet \
  neovim tree-sitter-cli \
  typescript typescript-language-server \
  vscode-langservers-extracted \
  "@fsouza/prettierd" bash-language-server \
  2>/dev/null || warn "Some npm packages failed (non-fatal)."

info "pip packages..."
run_as pip3 install --user --quiet --upgrade \
  pynvim neovim black isort ruff \
  2>/dev/null || warn "Some pip packages failed (non-fatal)."

ok "Node + Python tools done."

# =============================================================================
# 9. LAZYGIT
# =============================================================================
step "Installing lazygit"

if has lazygit; then
  ok "lazygit already installed."
else
  case "$OS" in
    macos) brew install lazygit || warn "lazygit brew install failed." ;;
    arch)  $PKG_INSTALL lazygit || warn "lazygit pacman install failed." ;;
    *)
      _lgv=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
        | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/') || true
      if [[ -n "${_lgv:-}" ]]; then
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${_lgv}_Linux_x86_64.tar.gz" \
          | tar xz -C /tmp lazygit 2>/dev/null \
          && sudo install /tmp/lazygit /usr/local/bin/lazygit \
          && ok "lazygit installed." \
          || warn "lazygit install failed (non-fatal)."
      else
        warn "Could not fetch lazygit version (non-fatal)."
      fi
      ;;
  esac
fi

# =============================================================================
# 10. NERD FONT — JetBrainsMono
# =============================================================================
step "Installing JetBrainsMono Nerd Font"

if [[ "$OS" == "macos" ]]; then
  if ls ~/Library/Fonts/JetBrainsMonoNerd* &>/dev/null 2>&1; then
    ok "Font already present."
  else
    brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null \
      && ok "Font installed." \
      || warn "Font install failed — visit https://nerdfonts.com"
  fi
else
  _font_dir="$REAL_HOME/.local/share/fonts/JetBrainsMono"
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    ok "Font already present."
  else
    mkdir -p "$_font_dir"
    curl -fsSL \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
      | tar xJ -C "$_font_dir" 2>/dev/null \
      && fc-cache -f "$_font_dir" \
      && ok "JetBrainsMono Nerd Font installed." \
      || warn "Font download failed — visit https://nerdfonts.com"
  fi
fi

# =============================================================================
# 11. NEOVIM CONFIG (d4c.nvim)
# =============================================================================
step "Cloning d4c.nvim"

NVIM_CONFIG="${XDG_CONFIG_HOME}/nvim"
NVIM_DATA="${XDG_DATA_HOME}/nvim"
NVIM_CACHE="${XDG_CACHE_HOME}/nvim"
NVIM_STATE="${XDG_STATE_HOME}/nvim"

info "Target: ${NVIM_CONFIG}"

for _d in "$NVIM_CONFIG" "$NVIM_DATA" "$NVIM_CACHE" "$NVIM_STATE"; do
  [[ -d "$_d" ]] && run_as mv "$_d" "${_d}.bak.${BACKUP_TS}" && warn "Backed up ${_d}" || true
done

mkdir -p "$(dirname "$NVIM_CONFIG")"
run_as git clone --depth 1 \
  "https://github.com/MuhammedZohaib/d4c.nvim.git" \
  "$NVIM_CONFIG"
chown -R "${REAL_USER}:${REAL_USER}" "$NVIM_CONFIG" 2>/dev/null || true
ok "Cloned to ${NVIM_CONFIG}."

LAZY_PATH="${NVIM_DATA}/lazy/lazy.nvim"
if [[ ! -d "$LAZY_PATH" ]]; then
  info "Bootstrapping lazy.nvim..."
  mkdir -p "${NVIM_DATA}/lazy"
  run_as git clone --filter=blob:none --depth 1 --branch stable \
    "https://github.com/folke/lazy.nvim.git" "$LAZY_PATH" &>/dev/null \
    && ok "lazy.nvim bootstrapped." \
    || warn "lazy.nvim clone failed — it will bootstrap on first nvim open."
  chown -R "${REAL_USER}:${REAL_USER}" "${NVIM_DATA}" 2>/dev/null || true
fi

info "Headless plugin sync..."
run_as nvim --headless "+Lazy! sync" +qa 2>/dev/null \
  && ok "Plugins synced." \
  || warn "Sync had warnings — open nvim once to finish."

# =============================================================================
# 12. PATH HYGIENE
# =============================================================================
step "PATH hygiene"

LOCAL_BIN="$REAL_HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

for _rc in "$REAL_HOME/.zshrc" "$REAL_HOME/.bashrc"; do
  if [[ -f "$_rc" ]] && ! grep -q "$LOCAL_BIN" "$_rc"; then
    echo "export PATH=\"${LOCAL_BIN}:\$PATH\"" >> "$_rc"
    chown "${REAL_USER}:${REAL_USER}" "$_rc" 2>/dev/null || true
    info "Added ~/.local/bin to PATH in ${_rc}"
  fi
done
export PATH="${LOCAL_BIN}:$PATH"
ok "PATH updated."

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}============================================================${RESET}"
echo -e "${GREEN}${BOLD}   d4c setup complete!${RESET}"
echo -e "${GREEN}${BOLD}============================================================${RESET}"
echo ""
echo -e "  ${GREEN}OK${RESET}  ~/.zshrc          written"
echo -e "  ${GREEN}OK${RESET}  ~/.tmux.conf      written"
echo -e "  ${GREEN}OK${RESET}  ~/.config/nvim    cloned"
echo -e "  ${GREEN}OK${RESET}  Oh My Zsh         powerlevel10k theme"
echo -e "  ${GREEN}OK${RESET}  tmux + TPM        Catppuccin status bar"
echo -e "  ${GREEN}OK${RESET}  lazygit           lg"
echo -e "  ${GREEN}OK${RESET}  Nerd Font         JetBrainsMono"
echo ""
echo -e "  ${YELLOW}${BOLD}Next steps:${RESET}"
echo -e "  1. ${CYAN}exec zsh${RESET}  or re-login for shell change"
echo -e "  2. ${CYAN}p10k configure${RESET}  to set up prompt"
echo -e "  3. ${CYAN}tmux${RESET}  then ${CYAN}Ctrl+A + I${RESET}  to install plugins"
echo -e "  4. ${CYAN}nvim${RESET}  — Treesitter parsers auto-install"
echo -e "  5. Set terminal font to ${BOLD}JetBrainsMono Nerd Font${RESET}"
echo ""
echo -e "  ${DIM}Splits: Prefix+|  Prefix+-  |  Panes: Ctrl+HJKL  |  Reload: Prefix+r${RESET}"
echo ""
