# ~/.zshrc

export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim

# ── History ────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks

# ── General ────────────────────────────────────────────────────────────────
setopt auto_cd               # type a folder name to cd into it
setopt interactive_comments  # allow # comments on the command line
setopt no_beep

# Case-insensitive cd: "cd developer/" works for ~/Developer.
# Only kicks in when the exact path doesn't exist.
cd() {
  if (( $# == 1 )) && [[ $1 != -* && ! -d $1 ]]; then
    setopt localoptions extendedglob nullglob
    local -a m=( (#i)${(b)1%/}(/) )
    if (( $#m == 1 )); then builtin cd -- "$m[1]"; return; fi
    (( $#m > 1 )) && { print -u2 "cd: ambiguous: ${(j:, :)m}"; return 1; }
  fi
  builtin cd "$@"
}

# ── Completion (Tab) ───────────────────────────────────────────────────────
# zsh-completions installs into /usr/share/zsh/site-functions, already on $fpath
autoload -Uz compinit && compinit -d ~/.cache/zcompdump
zmodload zsh/complist
zstyle ':completion:*' menu select                               # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'  # case-insensitive, fuzzy-ish
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{8}── %d ──%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh-completion
_comp_options+=(globdots)    # complete dotfiles too

# ── Keys (macOS-ish; keyd turns Cmd into Ctrl / Home / End) ───────────────
bindkey -e
bindkey '^[[H'    beginning-of-line   # Home  (Cmd+Left)
bindkey '^[[F'    end-of-line         # End   (Cmd+Right)
bindkey '^[[1~'   beginning-of-line
bindkey '^[[4~'   end-of-line
bindkey '^[[3~'   delete-char         # Delete
bindkey '^[[1;5D' backward-word       # Ctrl+Left
bindkey '^[[1;5C' forward-word        # Ctrl+Right
bindkey '^[[1;3D' backward-word       # Option+Left
bindkey '^[[1;3C' forward-word        # Option+Right
bindkey '^[b'     backward-word
bindkey '^[f'     forward-word
bindkey '^H'      backward-kill-word  # Ctrl/Cmd+Backspace
bindkey '^[^?'    backward-kill-word  # Option+Backspace
bindkey -M menuselect '^[[Z' reverse-menu-complete   # Shift+Tab in the menu

# ── Aliases ────────────────────────────────────────────────────────────────
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -l --icons=auto --group-directories-first --git'
alias la='eza -la --icons=auto --group-directories-first --git'
alias tree='eza --tree --icons=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# ── fzf: Ctrl+R fuzzy history, Ctrl+T fuzzy file picker ───────────────────
source <(fzf --zsh)

# ── Plugins ────────────────────────────────────────────────────────────────
# Grey inline suggestion from history; Right arrow (or End) accepts it,
# Option+Right accepts one word.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Colors commands green (valid) / red (unknown) as you type. Must come late.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# blue/gray instead of the default green; unknown commands stay red
for s in command builtin alias function precommand reserved-word hashed-command suffix-alias global-alias; do
  ZSH_HIGHLIGHT_STYLES[$s]='fg=#7aa2f7'
done
ZSH_HIGHLIGHT_STYLES[path]='fg=#c0caf5,underline'
for s in single-quoted-argument double-quoted-argument dollar-quoted-argument; do
  ZSH_HIGHLIGHT_STYLES[$s]='fg=#8b95a7'
done

# Up/Down search history for what you've typed so far
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=green,bold'
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# ── Prompt ─────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<
