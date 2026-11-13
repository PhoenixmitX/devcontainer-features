#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "screen installed" command -v screen
check "claude installed" bash -c "$HOME/.local/bin/claude --version || /usr/local/bin/claude --version"
check "aliases hooked into bash" grep -q personal-setup /etc/bash.bashrc
check "dc alias" bash -ic "alias dc" 
check "ll alias" bash -ic "alias ll"
check "la alias" bash -ic "alias la"
check "~/.claude owned by vscode" bash -c "[ \"\$(stat -c %U /home/vscode/.claude)\" = vscode ]"
check "post-start script" test -x /usr/local/share/personal-setup/post-start.sh

reportResults
