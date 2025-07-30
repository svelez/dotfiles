#! /usr/bin/env bash

# Unified secret retrieval script
# Attempts to retrieve a secret using the following sources, in order:
# 1. User session secrets directory (filesystem)
# 2. pass (the standard Unix password manager)
# 3. Apple Keychain (if available on macOS)

set -euo pipefail

# Check if identifier is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <identifier>" >&2
    echo "Example: $0 github/token" >&2
    exit 1
fi

IDENTIFIER="${1?First argument must be the identifier of the secret to retrieve}"
# Function to try workspaces secrets
try_workspaces_secrets() {
    local identifier="$1"
    # Convert to uppercase and translate forward slashes to underscores for filesystem storage
        local fs_safe_identifier="${identifier^^?}"
    fs_safe_identifier="${fs_safe_identifier//\//_}"

    # Get the secrets directory path
    local secrets_dir="/run/user/$(id -u)/secrets"
    local secret_file="${secrets_dir}/${fs_safe_identifier}"

    if [ -f "$secret_file" ]; then
        cat "$secret_file"
        return 0
    fi

    return 1
}

# Function to try pass password manager
try_pass() {
    local identifier="$1"

    if command -v pass >/dev/null 2>&1; then
        if pass show "$identifier" 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

# Function to try Apple Keychain
try_keychain() {
    local identifier="$1"

    if command -v security >/dev/null 2>&1; then
        # Try to find the password in keychain
        # Use the identifier as the service name and current user as account
        if security find-generic-password -a "$USER" -s "$identifier" -w 2>/dev/null; then
            return 0
        fi

        # Also try with the identifier as both service and account
        if security find-generic-password -a "$identifier" -s "$identifier" -w 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

# Try each method in order
try_workspaces_secrets "$IDENTIFIER" ||
try_keychain "$IDENTIFIER" ||
try_pass "$IDENTIFIER" ||
(
    echo "Secret '$IDENTIFIER' not found in any of the configured sources" >&2
    echo "Tried:" >&2
    upper_id="${IDENTIFIER^^}"
    echo "  1. Workspaces secrets: /run/user/$(id -u)/secrets/${upper_id//\//_}" >&2
    echo "  2. Pass password manager: $IDENTIFIER" >&2
    echo "  3. Apple Keychain: $IDENTIFIER" >&2
    exit 1
)
