# Claude Fable 5.1 hotfix

This branch is a temporary patch for CLIProxyAPI 7.2.145. It adds
`claude-fable-5-1` to the embedded Claude model catalog and preserves that one
entry when the normal remote catalog refresh runs.

The overlay leaves remote discovery enabled for every other model and preserves
the remote definition once upstream publishes `claude-fable-5-1` itself.

## Install on macOS with Homebrew

```bash
git clone --branch fable-5-1-hotfix https://github.com/frankleng/CLIProxyAPI.git
cd CLIProxyAPI
./scripts/install-fable-5-1-macos.sh
```

The installer:

- requires the Homebrew CLIProxyAPI 7.2.145 formula;
- installs Go through Homebrew if it is missing, then uses the project-pinned
  Go 1.26.0 toolchain;
- runs the focused registry tests;
- builds a version-stamped `7.2.145-fable5.1` binary;
- backs up the upstream Homebrew binary under
  `~/.local/state/cliproxyapi-fable-5-1/`;
- stores the patched binary beside the backup;
- installs a small formula-bin wrapper that restores `HOME` for launchd before
  executing the patched binary;
- restarts the existing Homebrew service.

Existing configuration and OAuth files are not modified.

## Restore the upstream binary

```bash
./scripts/install-fable-5-1-macos.sh --restore
```

Homebrew may replace the patched binary during an upgrade or reinstall. Re-run
the installer only while this hotfix is still needed.
