#!/usr/bin/env bash
set -Eeuo pipefail

CONTAINER="git-toolbox-test"
IMAGE="localhost/git-toolbox:local"

cleanup() {
    echo
    echo "Removing temporary toolbox..."
    toolbox rm --force "$CONTAINER" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "Creating temporary toolbox..."
toolbox create \
    --image "$IMAGE" \
    "$CONTAINER"

run() {
    toolbox run --container "$CONTAINER" "$@"
}

echo
echo "=== User and environment ==="

run whoami
run printenv HOME

echo
echo "=== Git ==="
run git --version

echo
echo "=== Git Credential Manager ==="
run git-credential-manager --version

echo
echo "=== GnuPG ==="
run gpg --version

echo
echo "=== Pass ==="
run pass --version

echo
echo "=== Pinentry ==="
run pinentry --version

echo
echo "=== GPG configuration ==="
run gpgconf --list-dirs homedir
run gpg --list-secret-keys

echo
echo "=== Password store ==="
run ls -ld "$HOME/.password-store"

echo
echo "All tests passed."
