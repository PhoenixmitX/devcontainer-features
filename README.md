# devcontainer-features

Personal [dev container features](https://containers.dev/implementors/features/), published to
`ghcr.io/phoenixmitx/devcontainer-features/<feature>`.

## `personal-setup`

For Debian/Ubuntu based images (built around UID 1000, the `vscode` user of the
`mcr.microsoft.com/devcontainers/base` images).

- **Aliases** for bash and zsh: `ll`, `la`, `l`, `dc` (`docker compose`, with tab completion via
  [complete-alias](https://github.com/cykerway/complete-alias)) and `docker` completion.
- **Shared Claude config**: the named volume `claude-code-config` is mounted at `/home/vscode/.claude`
  in every container, and `CLAUDE_CONFIG_DIR` points there, so login, settings and history are shared
  across all dev containers.
- **Claude Code** installed with the native installer for UID 1000, updated on every container start.
- **Remote Control**: on every start, `claude remote-control` runs as UID 1000 in a detached GNU screen
  session named `claude`, in the workspace folder. Attach with `screen -r claude` (detach with
  `Ctrl-a d`). On the very first container, run `claude auth login` once (in the screen session or any terminal), then restart the container or
  run `claude remote-control` in that screen session.
- **VS Code extensions** that always ship (see `src/personal-setup/devcontainer-feature.json`).

| Option           | Default | Description                                                     |
| ---------------- | ------- | --------------------------------------------------------------- |
| `remoteControl`  | `true`  | Start `claude remote-control` in screen session `claude`.       |
| `autoUpdate`     | `true`  | Run `claude update` on every container start.                   |
| `permissionMode` | `""`    | `--permission-mode` for sessions spawned through Remote Control. |

### Use it in every dev container (VS Code user settings)

```jsonc
"dev.containers.defaultFeatures": {
  "ghcr.io/phoenixmitx/devcontainer-features/personal-setup:1": {}
}
```

Or per project in `devcontainer.json`:

```jsonc
"features": {
  "ghcr.io/phoenixmitx/devcontainer-features/personal-setup:1": {}
}
```

## Publishing

Pushing changes under `src/` to `main` publishes automatically. To publish by hand:

```sh
gh workflow run release.yaml && gh run watch
```

Bump `version` in the feature's `devcontainer-feature.json` for every change; already published
versions are skipped. After the first publish, make the package public once under
*GitHub → Packages → devcontainer-features/personal-setup → Package settings → Change visibility*.
