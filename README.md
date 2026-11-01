
# Git Toolbox

A dedicated Fedora Toolbox image for Git development on Fedora CoreOS.

The image provides Git, Git Credential Manager (GCM), GnuPG, Pass, Pinentry and OpenSSH client utilities.

It keeps development tools isolated from the immutable Fedora CoreOS host while preserving user configuration, SSH access and GPG credentials.

The primary installation method uses the published image from GitHub Container Registry (GHCR).

Local image builds are intended for development, short build tests and functional verification.

## Features

- Fedora Toolbox base image
- Support for Fedora Toolbox images matching Fedora CoreOS releases
- Git from Fedora repositories
- Git Credential Manager (GCM) from official upstream releases
- GnuPG and GPG-backed credential storage
- Pass password manager
- Pinentry for terminal-based GPG authentication
- OpenSSH client
- Automated builds using GitHub Actions
- Image publishing to GitHub Container Registry (GHCR)
- Dependency updates using Renovate
- Automatic dependency updates and merging
- SHA256 verification of downloaded GCM releases
- Weekly image rebuilds

## Architecture

Git runs exclusively inside the Fedora Toolbox container.

The Fedora CoreOS host provides a small Git wrapper to execute Git inside the toolbox.

Toolbox shares the user's home directory between host and container. This allows Git, GCM, GnuPG and Pass to use the same configuration and credentials without storing them in the container image.

### Host and container responsibilities

**Installed in the container**

- Git
- Git Credential Manager
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

These directories are accessible from inside the toolbox through the shared home directory.

No personal credentials or private keys are included in the container image.

Recreating or updating the toolbox does not remove or reset the user's configuration and credentials.

| Component | Fedora CoreOS host | Toolbox container |
|---|---|---|
| Git executable | — | `/usr/bin/git` |
| Git wrapper | `~/.local/bin/git` | `/usr/local/bin/git-wrapper` |
| Git Credential Manager | — | `/usr/local/bin/git-credential-manager` |
| Git configuration | `~/.gitconfig` | `~/.gitconfig` (shared) |
| GPG configuration and keys | `~/.gnupg/` | `~/.gnupg/` (shared) |
| Pass password store | `~/.password-store/` | `~/.password-store/` (shared) |
| SSH configuration and keys | `~/.ssh/` | `~/.ssh/` (shared) |

## Prerequisites

A working Fedora CoreOS installation with Podman and Toolbox support is required.

The following host environment is expected:

- A regular user account with a properly configured home directory.
- The standard Fedora CoreOS Toolbox.
- An existing Git configuration or the information required to create one.
- An existing GPG key pair suitable for credential encryption.
- An initialized Pass password store.
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

The Git identity is configured inside the toolbox and stored in the shared global Git configuration.

Example:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

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

For the initial checkout of this repository, use Git from the standard Fedora CoreOS Toolbox.

The standard Toolbox already provides the Git environment needed to clone the repository before the dedicated Git Toolbox has been installed.

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

The initial repository checkout and subsequent repository maintenance can use the standard Fedora CoreOS Toolbox.

Once the dedicated Git Toolbox has been installed, Git operations for normal development can also use the new host Git wrapper.

## Installation on Fedora CoreOS

The primary installation method uses the published GHCR image.

### 1. Pull the image

For a public GHCR repository:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:latest
```

The tag represents the Fedora Toolbox major version.

For Fedora CoreOS 45, use:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:45
```

### 2. Create the toolbox

For Fedora CoreOS 44:

```bash
toolbox create \
    --image ghcr.io/homelan-git/git-toolbox:44 \
    git-toolbox
```

For Fedora CoreOS 45:

```bash
toolbox create \
    --image ghcr.io/homelan-git/git-toolbox:45 \
    git-toolbox
```

The toolbox shares the user's home directory with the host.

### 3. Configure Git Credential Manager

Run the GCM configuration command once inside the toolbox:

```bash
toolbox run --container git-toolbox \
    git-credential-manager configure
```

This configures Git to use GCM as its credential helper.

Because the home directory is shared, the global Git configuration is written to the host's `~/.gitconfig`.

Configure GPG as the credential store:

```bash
toolbox run --container git-toolbox \
    git config --global credential.credentialStore gpg
```

### 4. Configure Git identity

Configure your Git identity:

```bash
toolbox run --container git-toolbox \
    git config --global user.name "Your Name"

toolbox run --container git-toolbox \
    git config --global user.email "your.email@example.com"
```

Enable repository-specific credential lookup:

```bash
toolbox run --container git-toolbox \
    git config --global credential.useHttpPath true
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

### 6. Install the host Git wrapper

The repository provides the host wrapper in `bin/git`.

Install it:

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

The wrapper forwards Git commands to the dedicated toolbox.

The host does not need Git installed.

### 7. Verify the installation

Check Git through the host wrapper:

```bash
git --version
```

Check GCM:

```bash
toolbox run --container git-toolbox \
    git-credential-manager --version
```

Check GPG:

```bash
toolbox run --container git-toolbox \
    gpg --list-secret-keys
```

Check Pass:

```bash
toolbox run --container git-toolbox pass
```

The installation is complete.

Git commands invoked on the host are executed inside the dedicated toolbox.


## Git Configuration

Git configuration remains on the host and is accessible inside the toolbox through the shared home directory.

### Host Git wrapper

The host does not need Git installed for this setup.

The wrapper at `~/.local/bin/git` forwards all arguments to Git inside the toolbox.

The repository provides the following wrapper in `bin/git`:

```bash
#!/bin/bash

exec toolbox run --container git-toolbox \
    /usr/local/bin/git-wrapper "$@"
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

GCM uses Pass-compatible encrypted storage for its GPG credential store.

### Removing an old GCM configuration

If an older absolute GCM helper path is configured, remove it:

```bash
git config --global --unset-all credential.helper
```

Then run:

```bash
toolbox run --container git-toolbox \
    git-credential-manager configure
```

Set the credential store again:

```bash
toolbox run --container git-toolbox \
    git config --global credential.credentialStore gpg
```

### Verify the configuration

```bash
git config --global --get-all credential.helper
git config --global --get credential.useHttpPath
git config --global --get credential.credentialStore
```

Expected output:

```text
manager
true
gpg
```

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

### Pinentry

The Fedora `pinentry` package provides terminal-based Pinentry support.

Pinentry is used by the GPG agent to request passphrases, including during remote SSH sessions.

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

GCM uses this existing Pass store when configured with:

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

## Local Development and Testing

Local builds are intended for short development cycles, build verification and functional testing.

The primary usage is the published GHCR image.

### Build locally

From the repository root:

```bash
podman build \
    -t localhost/git-toolbox:local \
    -f Containerfile .
```

### Test locally

The integration test script creates a temporary Toolbox container using the locally built image.

Run:

```bash
./tests/test-toolbox.sh
```

The test container uses `localhost/git-toolbox:local`; no permanent toolbox installation is required.

The host must have an initialized GPG key and Pass password store for the integration tests to pass.

## Dependency Management

Renovate monitors the Containerfile for dependency updates.

The following dependencies are managed:

- Fedora Toolbox base image
- Fedora base image digest
- Git Credential Manager release
- GCM SHA256 checksum

GCM version and checksum are maintained together to ensure that downloaded release artifacts are verified against the correct digest.

Renovate submits pull requests for dependency updates.

Automatic merging is enabled for configured dependency updates.

GitHub waits for the required CI checks before merging.

After a successful merge into the default branch, GitHub Actions builds, tests and publishes the updated image to GHCR.

Fedora major upgrades are handled through Renovate pull requests. The workflow automatically detects the new Fedora version and publishes the image under the corresponding GHCR tag.

## Updating the Toolbox

The toolbox image can be updated independently of the Fedora CoreOS host.

### Update the image

Pull the latest image:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:latest
```

### Recreate the toolbox

Remove the existing toolbox:

```bash
toolbox rm git-toolbox
```

Create it again:

```bash
toolbox create \
    --image ghcr.io/homelan-git/git-toolbox:latest \
    git-toolbox
```

The host home directory is shared with the new container.

Git configuration, GPG keys, SSH keys and the Pass password store remain untouched.

The container image can therefore be replaced without reinstalling Git configuration, GPG keys or password-store contents.

### Fedora major upgrades

When moving to a newer Fedora CoreOS release, use the corresponding Fedora Toolbox image.

For example on Fedora CoreOS 44, after upgrading the host to Fedora CoreOS 45:

```bash
podman pull ghcr.io/homelan-git/git-toolbox:45

toolbox rm git-toolbox

toolbox create \
    --image ghcr.io/homelan-git/git-toolbox:45 \
    git-toolbox
```

The Git wrapper remains unchanged.

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

### Renovate

- [Renovate documentation](https://docs.renovatebot.com/)
- [Dockerfile manager](https://docs.renovatebot.com/modules/manager/dockerfile/)
- [Regex custom manager](https://docs.renovatebot.com/modules/manager/regex/)

## License

This project is licensed under the MIT License.

See [LICENSE](LICENSE) for the full license text.
