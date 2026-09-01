# ============================================================================
# ZSH Configuration
# ============================================================================

# --- History Configuration ---
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# --- Completion System ---
autoload -Uz compinit && compinit
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Plugins ---
[ -f ~/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source ~/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f ~/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source ~/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- System Colors ---
[[ -f ~/.dircolors ]] && eval $(dircolors -b ~/.dircolors) || eval $(dircolors -b)

# --- Aliases: General ---
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cat='batcat'
alias v='nvim'
alias vf='nvim $(fzf)'

# --- Aliases: Kubernetes ---
alias k='kubectl'
alias kk='k kustomize'
alias h='helm'

# --- Aliases: Docker ---
alias d='docker'
alias dop='docker ps'
alias dov='docker volume ls'
alias ld='lazydocker'

# --- Aliases: Incus ---
alias in='incus'
alias inn='in network'
alias ins='in storage'
alias inl='in list'
alias ine='in exec'
alias inrm='in remove'

# --- Aliases: System Management ---
alias spu='sudo apt update'
alias spa='sudo apt autoremove'
alias an='ansible'

# --- Exports ---
export LANG='en_US.UTF-8'
export FZF_DEFAULT_OPTS="--preview 'batcat --style=numbers --color=always --line-range :500 {}'"

# --- Key Bindings ---
# Navigate words with Ctrl + Arrow Keys
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# --- Dynamic Integrations ---
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
[ -f "$HOME/.local/bin/mise" ] && eval "$($HOME/.local/bin/mise activate zsh)"
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

# --- Shell Prompt Initialization ---
eval "$(starship init zsh)"

# --- Script  ---
# FZF
if command -v fzf &> /dev/null; then
  # Remove o preview e mantém apenas a janela limpa de busca
  export FZF_CTRL_R_OPTS="--height 40% --layout=reverse --border --no-preview"
  
  # Carrega os atalhos e autocompletar do FZF para o Zsh
  source <(fzf --zsh)
fi
