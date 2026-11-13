#!/usr/bin/env bash
# Runs as root at image build time. Debian/Ubuntu only.
set -euo pipefail

SHARE_DIR=/usr/local/share/personal-setup
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v apt-get >/dev/null; then
	echo "personal-setup: this feature needs a Debian-based image (apt-get not found)" >&2
	exit 1
fi

# The feature is built around UID 1000 (the 'vscode' user of the devcontainers base images).
# The user is stored by name: on Linux hosts the dev container tooling may later remap its
# UID to the host user's.
USERNAME="$(getent passwd 1000 | cut -d: -f1 || true)"
if [ -z "$USERNAME" ]; then
	USERNAME=vscode
	useradd --create-home --uid 1000 --shell /bin/bash "$USERNAME"
fi
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

# --- packages -----------------------------------------------------------------
missing=()
for pkg in curl ca-certificates screen bash-completion sudo; do
	dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if [ ${#missing[@]} -gt 0 ]; then
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends "${missing[@]}"
	rm -rf /var/lib/apt/lists/*
fi

# The post-start script uses sudo to fix the volume's ownership if needed.
if [ ! -e "/etc/sudoers.d/$USERNAME" ]; then
	echo "$USERNAME ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
	chmod 0440 "/etc/sudoers.d/$USERNAME"
fi

# --- shared files ---------------------------------------------------------------
mkdir -p "$SHARE_DIR"
install -m 0644 "$FEATURE_DIR/aliases.sh" "$SHARE_DIR/aliases.sh"
install -m 0755 "$FEATURE_DIR/post-start.sh" "$SHARE_DIR/post-start.sh"
cat > "$SHARE_DIR/config" <<CONF
USERNAME=$USERNAME
REMOTE_CONTROL=${REMOTECONTROL:-true}
AUTO_UPDATE=${AUTOUPDATE:-true}
PERMISSION_MODE=${PERMISSIONMODE:-}
CONF

# Completion for aliases (so `dc <TAB>` completes like `docker compose <TAB>`).
curl -fsSL https://raw.githubusercontent.com/cykerway/complete-alias/master/complete_alias \
	-o "$SHARE_DIR/complete_alias" \
	|| echo "personal-setup: could not download complete_alias, alias completion disabled" >&2

# --- aliases for every interactive shell ---------------------------------------
hook="[ -f $SHARE_DIR/aliases.sh ] && . $SHARE_DIR/aliases.sh"
for rc in /etc/bash.bashrc /etc/zsh/zshrc; do
	[ -f "$rc" ] || continue
	grep -qxF "$hook" "$rc" || printf '\n%s\n' "$hook" >> "$rc"
done

# --- Claude Code ----------------------------------------------------------------
# Pre-create the mount target owned by the user: Docker copies this ownership into
# the named volume the first time it is created.
mkdir -p "$USER_HOME/.claude" "$USER_HOME/.local/bin"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.claude" "$USER_HOME/.local"

# Native installer, per user (it keeps itself updated in ~/.local). Point its config
# dir at a throwaway path so nothing lands in ~/.claude and seeds the shared volume.
su - "$USERNAME" -c 'export CLAUDE_CONFIG_DIR="$(mktemp -d)"; curl -fsSL https://claude.ai/install.sh | bash; rm -rf "$CLAUDE_CONFIG_DIR"'
ln -sf "$USER_HOME/.local/bin/claude" /usr/local/bin/claude

echo "personal-setup: installed for $USERNAME ($USER_HOME)"
