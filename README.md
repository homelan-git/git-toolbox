# Git Toolbox

A dedicated Fedora Toolbox image for Git development on Fedora CoreOS.

The image provides a complete Git development environment based on Fedora Toolbox, including Git, Git Credential Manager (GCM), Git LFS, git-filter-repo, git-revise, git-delta and supporting authentication tools.

It keeps Git development tools isolated from the immutable Fedora CoreOS host while preserving the user's configuration, SSH access, GPG keys and credentials.

The primary installation method uses the published image from GitHub Container Registry (GHCR).

Local image builds are intended for development, build verification and functional testing.

## Features

- Fedora Toolbox base image matching Fedora CoreOS releases
- Git from Fedora repositories
- Git Credential Manager (GCM) from official upstream releases
- Git LFS for large file management
- git-filter-repo for rewriting Git history
- git-revise for editing and revising commits
- git-delta for improved Git diffs and interactive output
- GnuPG and GPG-backed credential storage
- Pass password manager
- Pinentry for terminal-based GPG authentication
- OpenSSH client
- Host-side Git wrapper for transparent toolbox execution
- Container-side Git wrapper with GPG terminal support
- Automated builds using GitHub Actions
- Image publishing to GitHub Container Registry (GHCR)
- Dependency updates using Renovate
- SHA256 verification of downloaded GCM releases
- Automated image rebuilds

## Architecture

Git runs exclusively inside the dedicated Fedora Toolbox container.

The Fedora CoreOS host provides a small Git wrapper that transparently executes Git inside the toolbox.

The wrapper allows Git commands to be invoked directly from the host without requiring a Git installation on the host itself.

Toolbox shares the user's home directory between host and container. This allows Git, GCM, GnuPG, Pass and SSH to use the same configuration and credentials without storing personal data in the container image.

### Host and container responsibilities

**Installed in the container**

- Git
- Git Credential Manager
- Git LFS
- git-filter-repo
- git-revise
- git-delta
- GnuPG
- Pass
- Pinentry
- OpenSSH client

**Stored on the host**

- Git configuration
- GPG private and public keys
- GPG agent configuration
- Pass password store
- SSH private keys and configuration
- Host-side Git wrapper

These directories are accessible from inside the toolbox through the shared home directory.

No personal credentials, private keys or password-store data are included in the container image.

Recreating or updating the toolbox does not remove or reset the user's configuration and credentials.

| Component | Fedora CoreOS host | Toolbox container |
|---|---|---|
| Git executable | — | `/usr/bin/git` |
| Host Git wrapper | `~/.local/bin/git` | — |
| Container Git wrapper | — | `/usr/local/bin/git-wrapper` |
| Git Credential Manager | — | `/usr/local/bin/git-credential-manager` |
| Git configuration | `~/.gitconfig` | `~/.gitconfig` (shared) |
| GPG configuration and keys | `~/.gnupg/` | `~/.gnupg/` (shared) |
| Pass password store | `~/.password-store/` | `~/.password-store/` (shared) |
| SSH configuration and keys | `~/.ssh/` | `~/.ssh/` (shared) |

### Command execution

The execution flow is:

```text
Fedora CoreOS host
       |
       | git status
       v
~/.local/bin/git
       |
       | toolbox run --container git-toolbox
       v
/usr/local/bin/git-wrapper
       |
       | GPG_TTY configuration
       v
/usr/bin/git
       |
       +---- Git Credential Manager
       |
       +---- GPG / Pass
       |
       +---- SSH
```

The host wrapper forwards all arguments to the container-side Git wrapper.

The container wrapper configures `GPG_TTY` when running interactively. This ensures that GPG and Pinentry can access the correct terminal, including during SSH sessions.

## Prerequisites

A working Fedora CoreOS installation with Podman and Toolbox support is required.

The following host environment is expected:

- A regular user account with a properly configured home directory.
- Toolbox support.
- An existing GPG key pair suitable for credential encryption.
- An initialized Pass password store, if GPG-backed credential storage is used.
- SSH keys and configuration, if SSH authentication is required.

### Required host configuration

| Component | Host location | Requirement |
|---|---|---|
| Git configuration | `~/.gitconfig` | User identity and preferences |
| GPG keys | `~/.gnupg/` | Existing private and public keys |
| GPG agent | `~/.gnupg/gpg-agent.conf` | Optional agent configuration |
| Pass | `~/.password-store/` | Initialized password store |
| SSH | `~/.ssh/` | Keys and configuration, if required |

### Git identity

The Git identity is configured in the shared global Git configuration.

Example:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

The configuration is stored on the host and is available inside the toolbox.

### GPG keys

The toolbox expects an existing GPG key suitable for credential encryption.

Check available secret keys:

```bash
gpg --list-secret-keys
```

The private key must be available through the shared home directory.

### Pass password store

The password store must be initialized with the appropriate GPG key.

Check the password store:

```bash
pass
```

If the password store has not been initialized:

```bash
pass init YOUR_GPG_KEY_ID
```

### Important

The toolbox image does not contain personal configuration, private keys, credentials or password-store data.

It provides the software required to use an existing development environment.

The initial host configuration is a prerequisite and is not automatically created or migrated by installing the toolbox.

All personal data remains on the host and is accessible inside the toolbox through the shared home directory.

## Initial Repository Checkout

For the initial checkout of this repository, use the standard Fedora CoreOS Toolbox.

The standard Toolbox provides the Git environment needed to clone the repository before the dedicated Git Toolbox has been installed.

Create a working directory:

```bash
mkdir -p ~/Projects
cd ~/Projects
```

Clone the repository:

```bash
toolbox run git clone \
    https://github.com/homelan-git/git-toolbox.git
```

Enter the repository:

```bash
cd ~/Projects/git-toolbox
```

Once the dedicated Git Toolbox has been installed, normal Git operations can use the host-side Git wrapper.

## Installation on Fedora CoreOS

The primary installation method uses the published GHCR image.

The image tags correspond to Fedora major versions. For example, the `44` tag is intended for Fedora CoreOS 44.

### 1. Pull the image

For Fedora CoreOS 44:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:44
```

Alternatively, use the `latest` tag:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:latest
```

For reproducible installations, prefer the explicit Fedora major-version tag.

### 2. Create the toolbox

For Fedora CoreOS 44:

```bash
toolbox create \
    --image ghcr.io/homelan-git/git-toolbox:44 \
    git-toolbox
```

The toolbox shares the user's home directory with the host.

### 3. Configure Git Credential Manager

Configure GCM once inside the toolbox:

```bash
toolbox run --container git-toolbox \
    git-credential-manager configure
```

This configures Git to use Git Credential Manager as its credential helper.

Because the home directory is shared, the global Git configuration is written to the host's `~/.gitconfig`.

Configure GPG as the credential store:

```bash
toolbox run --container git-toolbox \
    git config --global credential.credentialStore gpg
```

Enable repository-specific credential lookup:

```bash
toolbox run --container git-toolbox \
    git config --global credential.useHttpPath true
```

### 4. Configure Git identity

Configure your Git identity:

```bash
toolbox run --container git-toolbox \
    git config --global user.name "Your Name"

toolbox run --container git-toolbox \
    git config --global user.email "your.email@example.com"
```

### 5. Verify GPG and Pass

List available secret keys:

```bash
toolbox run --container git-toolbox \
    gpg --list-secret-keys
```

If the password store has not been initialized:

```bash
toolbox run --container git-toolbox \
    pass init YOUR_GPG_KEY_ID
```

Verify the password store:

```bash
toolbox run --container git-toolbox pass
```

## Git Configuration

Git configuration remains on the host and is accessible inside the toolbox through the shared home directory.

### Git Delta

The image includes [Git Delta](https://github.com/dandavison/delta) as the default Git pager.

The following system-wide settings are configured in the image (`/etc/gitconfig`):

```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    line-numbers = true
    side-by-side = true
```

This provides enhanced syntax-highlighted diffs, side-by-side comparisons, line numbers and navigation between diff sections.

No additional configuration is required on the host.

These settings are defined at system level inside the container and apply to all users unless overridden by repository or user configuration.

### Host Git wrapper

The host does not need Git installed for this setup.

The wrapper at `~/.local/bin/git` forwards all arguments to Git inside the dedicated toolbox.

The repository provides the following wrapper in `bin/git`:

```bash
#!/bin/bash

exec toolbox run --container git-toolbox \
    /usr/local/bin/git-wrapper "$@"
```

Install it with:

```bash
install -Dm0755 bin/git ~/.local/bin/git
```

Ensure that `~/.local/bin` is included in the host's `PATH`.

For Bash, add the following to `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Reload the shell configuration:

```bash
source ~/.bashrc
```

### Container Git wrapper

The container provides `/usr/local/bin/git-wrapper`:

```bash
#!/bin/bash
set -e

if [[ -t 0 ]]; then
    export GPG_TTY="$(tty)"
fi

exec /usr/bin/git "$@"
```

This sets `GPG_TTY` inside the container, ensuring that GPG and Pinentry use the correct terminal, including remote SSH sessions.

### Recommended ~/.gitconfig

```ini
[user]
    name = Your Name
    email = your.email@example.com

[credential]
    helper = manager
    useHttpPath = true
    credentialStore = gpg
```

Configuration details:

- `helper = manager`: Uses Git Credential Manager.
- `useHttpPath = true`: Includes the repository path when looking up credentials.
- `credentialStore = gpg`: Stores credentials encrypted using GPG.

GCM uses GPG-backed credential storage and the existing GPG environment.

### Removing an old GCM configuration

If an older absolute GCM helper path is configured, remove it:

```bash
git config --global --unset-all credential.helper
```

Then configure GCM again inside the toolbox:

```bash
toolbox run --container git-toolbox \
    git-credential-manager configure
```

Set the credential store:

```bash
git config --global credential.credentialStore gpg
```

Enable repository-specific credential lookup:

```bash
git config --global credential.useHttpPath true
```

### Verify the configuration

```bash
git config --show-origin --get-all credential.helper
git config --global --get credential.useHttpPath
git config --global --get credential.credentialStore
```

Expected values:

```text
manager
true
gpg
```

The helper may be displayed with its configuration origin and additional formatting.

## Git Tools

The image includes several Git-specific tools that extend the standard Git functionality.

All tools are installed inside the container and are available through the shared Git environment.

### Git

Git is installed from Fedora repositories.

Check the version:

```bash
git --version
```

Git commands invoked through the host wrapper are executed inside the dedicated toolbox.

### Git Credential Manager

Git Credential Manager handles authentication against Git hosting services such as GitHub.

Check the version:

```bash
toolbox run --container git-toolbox \
    git-credential-manager --version
```

Check the configured helper:

```bash
git config --show-origin --get-all credential.helper
```

GCM is installed at:

```text
/usr/local/bin/git-credential-manager
```

### Git LFS

Git LFS provides support for storing large files outside the regular Git object database.

Check the version:

```bash
git lfs version
```

Initialize Git LFS for the current user:

```bash
git lfs install
```

Example: Track binary assets:

```bash
git lfs track "*.psd"
git lfs track "*.zip"
```

The resulting `.gitattributes` file should be committed to the repository.

Inspect tracked files:

```bash
git lfs ls-files
```

### git-filter-repo

`git-filter-repo` is used to rewrite Git history.

Typical use cases include:

- Removing sensitive information from historical commits.
- Replacing author and committer identities.
- Removing unwanted files from repository history.
- Splitting or restructuring repositories.
- Cleaning up historical repository content.

Check the version:

```bash
git filter-repo --version
```

Example: Rewrite historical author identities using a mailmap:

```bash
git filter-repo --force --mailmap mailmap.txt
```

**Important:** History rewriting changes commit IDs and invalidates existing references to rewritten commits.

Before rewriting a repository, create a backup:

```bash
git bundle create ../repository-before-rewrite.bundle --all
```

After rewriting, verify the resulting history before force-pushing to the remote repository.

### git-revise

`git-revise` provides an alternative workflow for editing and revising commits.

It is useful for:

- Modifying earlier commits.
- Reorganizing commit history.
- Editing commit messages.
- Splitting and combining commits.
- Preparing a clean commit series before pushing.

Check the version:

```bash
git revise --version
```

Consult the built-in help for available operations:

```bash
git revise --help
```

### git-delta

`git-delta` provides improved syntax highlighting and navigation for Git diffs.

Check the version:

```bash
delta --version
```

Configure Delta for the current user:

```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
```

These settings belong in the user's global Git configuration.

They must not be written to `/etc/gitconfig` unless the container is deliberately configured for privileged system-wide configuration.

The resulting configuration is stored in the shared `~/.gitconfig`.

## GPG Configuration

GPG keys and configuration remain on the host in:

`~/.gnupg/`

The directory is shared with the toolbox.

Existing GPG keys can therefore be used without importing them again.

### List available secret keys

```bash
gpg --list-secret-keys
```

### GPG Agent

The GPG agent configuration is stored in:

`~/.gnupg/gpg-agent.conf`

Example:

```ini
default-cache-ttl 3600
max-cache-ttl 28800
```
Both settings specify cache durations in seconds:

| Setting | Seconds | Minutes | Meaning |
|---|---:|---:|---|
| `default-cache-ttl` | 3,600 | 60 min | Default duration for caching a passphrase after use |
| `max-cache-ttl` | 28,800 | 480 min (8 h) | Maximum lifetime of a cached passphrase, regardless of subsequent use |

**Important distinction:**

- `default-cache-ttl`: The cache timeout is refreshed when the cached passphrase is used. After 60 minutes without use, it expires.
- `max-cache-ttl`: Sets the absolute maximum lifetime of the cached passphrase. Even if it is used repeatedly, it expires after 8 hours.

The maximum lifetime therefore takes precedence over repeated cache refreshes.

These settings balance convenience and security by avoiding frequent passphrase prompts while ensuring that cached credentials eventually expire.

### Pinentry

The Fedora `pinentry` package provides terminal-based Pinentry support.

Pinentry is used by the GPG agent to request passphrases, including during remote SSH sessions.

The container-side Git wrapper sets `GPG_TTY` for interactive Git operations.

## Password Store

Pass stores encrypted credentials in:

`~/.password-store/`

The directory is shared with the toolbox.

### Initialize the password store

If necessary:

```bash
pass init YOUR_GPG_KEY_ID
```

### Verify the password store

```bash
pass
```

GCM uses GPG-backed credential storage when configured with:

```ini
[credential]
    credentialStore = gpg
```

No credential database needs to be copied into the container.

## SSH and GPG Terminal Support

The Git wrapper inside the container sets `GPG_TTY` dynamically before starting Git.

This ensures that GPG and Pinentry use the correct terminal, including remote SSH sessions.

SSH keys and configuration remain on the host in:

`~/.ssh/`

The shared home directory makes them available inside the toolbox.

## Dependency Management

Renovate monitors the Containerfile and repository configuration for dependency updates.

The following dependencies are managed:

- Fedora Toolbox base image
- Fedora base image digest
- Git Credential Manager release
- GCM SHA256 checksum

GCM version and checksum are maintained together to ensure that downloaded release artifacts are verified against the correct digest.

Fedora packages are installed from the configured Fedora repositories during image builds.

Renovate submits pull requests for dependency updates.

Automatic merging is enabled for configured dependency updates.

GitHub waits for the required CI checks before merging.

After a successful merge into the default branch, GitHub Actions builds, tests and publishes the updated image to GHCR.

Fedora major upgrades are handled through Renovate pull requests. The workflow automatically detects the new Fedora version and publishes the image under the corresponding GHCR tag.

## Updating the Toolbox

The toolbox image can be updated independently of the Fedora CoreOS host.

### Update the image

Pull the latest image for the current Fedora major version:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:44
```

### Recreate the toolbox

Stop the existing container if necessary:

```bash
podman stop git-toolbox
```

Remove the existing toolbox:

```bash
toolbox rm git-toolbox
```

Create it again:

```bash
toolbox create \
    --image ghcr.io/homelan-git/git-toolbox:44 \
    git-toolbox
```

The host home directory is shared with the new container.

Git configuration, GPG keys, SSH keys and the Pass password store remain untouched.

The container image can therefore be replaced without reinstalling Git configuration, GPG keys or password-store contents.

### Fedora major upgrades

When moving to a newer Fedora CoreOS release, use the corresponding Fedora Toolbox image.

For example, after upgrading the host from Fedora CoreOS 44 to Fedora CoreOS 45:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:45

podman stop git-toolbox

toolbox rm git-toolbox

toolbox create \
    --image ghcr.io/homelan-git/git-toolbox:45 \
    git-toolbox
```

The host Git wrapper remains unchanged.

## Repository Structure

```text
git-toolbox/
├── .github/
│   └── workflows/
│       └── build.yml
├── bin/
│   ├── git
│   └── git-wrapper
├── tests/
│   └── test-toolbox.sh
├── Containerfile
├── renovate.json
├── LICENSE
└── README.md
```

## Appendix: Official Documentation

### Fedora Toolbox

- [Fedora Toolbox documentation](https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/)
- [Toolbx project and documentation](https://github.com/containers/toolbox)
- [Toolbx container creation reference](https://github.com/containers/toolbox/blob/main/doc/toolbox-create.1.md)

### Podman

- [Podman documentation](https://docs.podman.io/)

### Git

- [Git documentation](https://git-scm.com/docs)
- [Git configuration reference](https://git-scm.com/docs/git-config)
- [Git credential helpers](https://git-scm.com/docs/gitcredentials)

### Git Credential Manager

- [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager)
- [Installation instructions](https://github.com/git-ecosystem/git-credential-manager/blob/main/README.md)
- [Configuration reference](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/configuration.md)

### Git LFS

- [Git LFS documentation](https://git-lfs.com/)
- [Git LFS repository](https://github.com/git-lfs/git-lfs)

### git-filter-repo

- [git-filter-repo repository](https://github.com/newren/git-filter-repo)
- [git-filter-repo documentation](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt)

### git-revise

- [git-revise repository](https://github.com/mystor/git-revise)

### git-delta

- [git-delta repository](https://github.com/dandavison/delta)

### Renovate

- [Renovate documentation](https://docs.renovatebot.com/)
- [Dockerfile manager](https://docs.renovatebot.com/modules/manager/dockerfile/)
- [Regex custom manager](https://docs.renovatebot.com/modules/manager/regex/)

## License

This project is licensed under the MIT License.

See [LICENSE](LICENSE) for the full license text.
