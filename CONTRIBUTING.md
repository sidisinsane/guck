# Contributing

## Adding Scripts

1. Place the script in the appropriate category directory under `scripts/`.
   If no suitable category exists, create one.
2. Set the executable bit before committing:
   ```bash
   git add scripts/category/script.sh
   git update-index --chmod=+x scripts/category/script.sh
   git commit
   ```

## Conventions

### Structure

- Scripts are grouped by category under `scripts/`.
- An orchestrator script is named after its parent directory (e.g.
  `scripts/project/project.sh`). It sources helper scripts and composes
  their output.
- Helper scripts are prefixed with `_detect-` and are sourced by the
  orchestrator, not invoked directly (e.g. `scripts/project/_detect-vcs.sh`).
- Standalone scripts are self-contained and invoked directly or via the `guck`
  dispatcher (e.g. `scripts/git/status.sh`, `scripts/env/system.sh`).

### Naming

- Orchestrators: `<category>.sh`
- Helpers: `_detect-<name>.sh`
- Standalones: `<name>.sh`
- Functions: `detect_<name>` mirroring the filename (hyphens become underscores)

### Detection hierarchy

When detecting versions or tools, prefer sources in this order:

1. **Pinned** — project-specific version files (`.python-version`, `.node-version`, `rust-toolchain.toml`)
2. **Declared** — manifest constraints (`go.mod`, `pyproject.toml`, `package.json` engines)
3. **Installed** — binary query (`go version`, `node --version`)
4. **Manager** — version manager dotfiles (`.tool-versions`, `.nvmrc`)

### Output

- Output format is YAML for structured data, TSV where tabular makes more sense.
- Standalone scripts produce no top-level key wrapper — output begins directly
  with the relevant fields or list entries.
- Produce no output and `return 1` when nothing is detected — do not print
  placeholders or error messages.
- Use `return 1` not `exit 1` in sourced scripts.

### hashfm blocks

Every script — orchestrator, helper, or standalone — must have a hashfm block
as its first comment block. Follow these rules:

- `description` should be as short as possible while remaining accurate.
- Use a folded scalar (`>`) only when the description cannot fit on one line
  within 80 characters.
- Add `requires`, `populates`, and any other relevant fields where they add
  value.
- `name` is optional — omit it when the filename is self-explanatory.

Example:

```bash
#!/usr/bin/env bash
# ---
# description: Detects the VCS in use and reports repository state.
# usage: source _detect-vcs.sh && detect_vcs [dir]
# populates:
#   detected_vcs: associative array of VCS metadata
# exits:
#   0: success
#   1: no VCS detected
# ---
```
