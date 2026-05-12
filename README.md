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

## Usage

Scripts are invoked via the `guck` dispatcher as `guck <category> <endpoint>`.

| Command | Description |
|---|---|
| `guck env build-tools [runtime...]` | Reports installed build tools, optionally filtered by runtime group. |
| `guck env container-tools` | Reports installed container and orchestration tools and their versions. |
| `guck env data-tools` | Reports installed data processing tools and their versions. |
| `guck env network-tools` | Reports installed network tools and their versions. |
| `guck env system` | Reports OS, architecture, and shell of the current system. |
| `guck env vcs-tools` | Reports installed version control tools and their versions. |
| `guck git changelog` | Reports commits since the last tag as a TSV index. |
| `guck git status` | Reports the current git repository status. |
| `guck project dependency-snapshot <manager> [--dev\|--all]` | Reports a dependency snapshot for the specified package manager. |
| `guck project info` | Reports a structured snapshot of the current project. |
| `guck project stats` | Reports file counts and line counts, sorted by relevance. |

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

**`guck project dependency-snapshot npm`**

```tsv
name	version	depth
astro	2.9.6	1
dotenv	16.3.1	1
@astrojs/compiler	1.7.0	2
@astrojs/markdown-remark	2.2.1	2
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
name                    path                                        description
build-tools             ./scripts/env/build-tools.sh               Reports installed build tools, optionally filtered by runtime group.
changelog               ./scripts/git/changelog.sh                 Reports commits since the last tag as a TSV index.
dependency-snapshot     ./scripts/project/dependency-snapshot.sh   Reports a dependency snapshot for the specified package manager.
...
```

---

## Contributing

This is a personal project. The conventions in [CONTRIBUTING.md](CONTRIBUTING.md)
document how scripts are structured, which may be useful if you fork the project.
