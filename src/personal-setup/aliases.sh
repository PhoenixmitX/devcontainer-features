# Sourced from /etc/bash.bashrc and /etc/zsh/zshrc by the personal-setup feature.

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias dc='docker compose'

# Claude Code's config lives on the shared ~/.claude volume.
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

if [ -n "${BASH_VERSION:-}" ] && [[ $- == *i* ]]; then
	command -v docker >/dev/null 2>&1 && eval "$(docker completion bash 2>/dev/null)"
	if [ -f /usr/local/share/personal-setup/complete_alias ]; then
		. /usr/local/share/personal-setup/complete_alias
		complete -F _complete_alias dc
	fi
fi
