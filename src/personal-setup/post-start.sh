#!/usr/bin/env bash
# postStartCommand: runs on every container start, in the workspace folder.
# Updates Claude Code and starts `claude remote-control` as UID 1000 inside a
# detached GNU screen session named 'claude' (attach with `screen -r claude`).
set -uo pipefail

. /usr/local/share/personal-setup/config

USERNAME="$(getent passwd 1000 | cut -d: -f1)"
USER_HOME="$(getent passwd 1000 | cut -d: -f6)"
WORKDIR="$PWD"

as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }
as_user() {
	if [ "$(id -u)" = 1000 ]; then
		"$@"
	else
		as_root runuser -u "$USERNAME" -- env HOME="$USER_HOME" PATH="$PATH" "$@"
	fi
}

# A volume created by something other than this feature may be root-owned.
if [ "$(stat -c %u "$USER_HOME/.claude" 2>/dev/null)" != 1000 ]; then
	as_root chown 1000:1000 "$USER_HOME/.claude" || echo "personal-setup: could not chown $USER_HOME/.claude" >&2
fi

export CLAUDE_CONFIG_DIR="$USER_HOME/.claude"
export PATH="$USER_HOME/.local/bin:$PATH"
claude="$USER_HOME/.local/bin/claude"

if [ "$AUTO_UPDATE" = true ]; then
	as_user env CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR" "$claude" update || echo "personal-setup: claude update failed" >&2
fi

[ "$REMOTE_CONTROL" = true ] || exit 0

if as_user screen -ls claude 2>/dev/null | grep -q '\.claude[[:space:]]'; then
	echo "personal-setup: screen session 'claude' already running"
	exit 0
fi

args=(remote-control)
[ -n "$PERMISSION_MODE" ] && args+=(--permission-mode "$PERMISSION_MODE")

# Keep a shell open after remote-control exits (e.g. not logged in yet), so
# `screen -r claude` shows what happened and lets you run `claude` to log in.
cmd="cd $(printf %q "$WORKDIR") && $(printf %q "$claude") ${args[*]}
rc=\$?
echo
echo \"claude remote-control exited (\$rc). Run 'claude auth login', then 'claude remote-control'.\"
exec bash -l"
as_user env CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR" screen -dmS claude bash -lc "$cmd"
echo "personal-setup: started 'claude remote-control' in screen session 'claude' ($WORKDIR)"
