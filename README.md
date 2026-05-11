# guck

**Guck** — German for *look* — is a collection of shell scripts that report
structured information an LLM agent needs to act, without the noise it doesn't.

An agent working without context will go looking for it — reading files, running
commands, making assumptions. Guck anticipates that need. Before the agent asks,
you already have the answer: what runtime the project uses, what tools are
installed, how far the repository is from its last release. No guessing, no
digging, no back and forth.

---

## Getting Started

**Install (macOS and Linux):**

```bash
curl -o- https://raw.githubusercontent.com/sidisinsane/guck/main/install.sh | bash
```

**Install (Windows):**

```powershell
irm https://raw.githubusercontent.com/sidisinsane/guck/main/install.ps1 | iex
```

**Clone (for development):**

```bash
git clone https://github.com/sidisinsane/guck.git
cd guck
```

---

## Scripts

Once installed, scripts are invoked via the `guck` dispatcher:

```bash
guck project info                 # snapshot of the current project
guck project info /path/to/dir    # snapshot of a specific directory
guck git status                   # git repository status
guck git changelog                # commits since last tag
guck env system                   # OS, architecture, and shell
guck env build-tools              # installed build tools
guck env build-tools go nodejs    # filtered by runtime
```

| Script | Description |
|---|---|
| [`scripts/project/info.sh`] | Reports a structured snapshot of the current project. |
| [`scripts/git/status.sh`] | Reports the current git repository status. |
| [`scripts/git/changelog.sh`] | Reports commits since the last tag as a TSV index. |
| [`scripts/env/system.sh`] | Reports OS, architecture, and shell of the current system. |
| [`scripts/env/build-tools.sh`] | Reports installed build tools, optionally filtered by runtime. |
| [`scripts/env/container-tools.sh`] | Reports installed container and orchestration tools. |
| [`scripts/env/data-tools.sh`] | Reports installed data processing tools. |
| [`scripts/env/network-tools.sh`] | Reports installed network tools. |
| [`scripts/env/vcs-tools.sh`] | Reports installed version control tools. |

### Examples

**`guck project info`**

```yaml
environments:
  - runtime: nodejs
    language: typescript
    version:
      required: 20.0.0+
      installed: 20.11.0
    manager:
      name: pnpm
      installed: 8.6.0
    path: .
vcs:
  type: git
  branch: main
  last_tag: v1.2.0
  commits_since_tag: 3
  uncommitted_changes: 1
```

**`guck git status`**

```yaml
branch: feat/dispatcher
ahead: 2
staged: 1
unstaged: 3
untracked: 0
stash: 0
```

---

## Using with hashfm-agent

Every script in guck has a [hashfm](https://github.com/sidisinsane/hashfm) block
— a structured metadata comment that makes it self-describing. Combined with
[hashfm-agent](https://github.com/sidisinsane/hashfm-agent), this or any other
collection becomes directly consumable by an LLM agent.

Run once to generate a token-efficient index:

```bash
hashfm-agent generate ./scripts
```

The result is a compact index the agent uses to discover and invoke the right
script without reading documentation:

```tsv
name                  path                              description
build-tools           ./scripts/env/build-tools.sh      Reports installed build tools, optionally filtered by runtime group.
changelog             ./scripts/git/changelog.sh        Reports commits since the last tag as a TSV index.
container-tools       ./scripts/env/container-tools.sh  Reports installed container and orchestration tools and their versions.
data-tools            ./scripts/env/data-tools.sh       Reports installed data processing tools and their versions.
info                  ./scripts/project/info.sh         Reports a structured snapshot of the current project.
network-tools         ./scripts/env/network-tools.sh    Reports installed network tools and their versions.
status                ./scripts/git/status.sh           Reports the current git repository status.
system                ./scripts/env/system.sh           Reports OS, architecture, and shell of the current system.
vcs-tools             ./scripts/env/vcs-tools.sh        Reports installed version control tools and their versions.
```

---

## Contributing

This is a personal project. The conventions in [CONTRIBUTING.md](CONTRIBUTING.md)
document how scripts are structured, which may be useful if you fork the project.
