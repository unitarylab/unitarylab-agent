#!/usr/bin/env bash
set -e

# UnitaryLab CLI Installation Script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/unitarylab/unitarylab-agent/main/install.sh | bash
#   wget -qO- https://raw.githubusercontent.com/unitarylab/unitarylab-agent/main/install.sh | bash
#
# Optional:
#   VERSION=0.1.5 bash install.sh
#   VERSION=latest bash install.sh
#   PREFIX=$HOME/.local bash install.sh
#   PREFIX=/usr/local bash install.sh
#
# Use with sudo:
#   curl -fsSL <install-url> | sudo bash
#
# Default install path:
#   root:     /usr/local/bin/unitarylab
#   non-root: $HOME/.local/bin/unitarylab

echo "Installing UnitaryLab CLI..."

REPO="unitarylab/unitarylab-agent"
CLI_NAME="unitarylab"
VERSION="${VERSION:-latest}"

# ------------------------------------------------------------------------------
# Detect platform
# ------------------------------------------------------------------------------

case "$(uname -s || echo "")" in
  Darwin*) PLATFORM="macos" ;;
  Linux*) PLATFORM="linux" ;;
  *)
    echo "Error: Unsupported operating system." >&2
    echo "Only macOS and Linux are supported by this installer." >&2
    echo "" >&2
    echo "For Windows, please download unitarylab-windows-x86_64.exe from:" >&2
    echo "  https://github.com/${REPO}/releases" >&2
    exit 1
    ;;
esac

# ------------------------------------------------------------------------------
# Detect architecture
# ------------------------------------------------------------------------------

case "$(uname -m || echo "")" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "Error: Unsupported architecture: $(uname -m)" >&2
    echo "Supported architectures: x86_64, arm64" >&2
    exit 1
    ;;
esac

# Current release assets do not include macOS x86_64.
if [ "$PLATFORM" = "macos" ] && [ "$ARCH" = "x86_64" ]; then
  echo "Error: macOS x86_64 binary is not available in the current release." >&2
  echo "" >&2
  echo "Available macOS binary:" >&2
  echo "  unitarylab-macos-arm64" >&2
  echo "" >&2
  echo "If you are using Apple Silicon, please run this script in an arm64 shell." >&2
  echo "You can check your architecture with:" >&2
  echo "  uname -m" >&2
  exit 1
fi

BINARY_NAME="${CLI_NAME}-${PLATFORM}-${ARCH}"
CHECKSUM_NAME="SHA256SUMS-${PLATFORM}-${ARCH}.txt"

# ------------------------------------------------------------------------------
# GitHub authentication support
# ------------------------------------------------------------------------------

CURL_AUTH=()
WGET_AUTH=()

if [ -n "${GITHUB_TOKEN:-}" ]; then
  CURL_AUTH=(-H "Authorization: token ${GITHUB_TOKEN}")
  WGET_AUTH=(--header="Authorization: token ${GITHUB_TOKEN}")
fi

# ------------------------------------------------------------------------------
# Resolve download URLs
# ------------------------------------------------------------------------------

case "$VERSION" in
  ""|"latest")
    DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${BINARY_NAME}"
    CHECKSUM_URL="https://github.com/${REPO}/releases/latest/download/${CHECKSUM_NAME}"
    ;;
  v*)
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"
    CHECKSUM_URL="https://github.com/${REPO}/releases/download/${VERSION}/${CHECKSUM_NAME}"
    ;;
  *)
    VERSION="v${VERSION}"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"
    CHECKSUM_URL="https://github.com/${REPO}/releases/download/${VERSION}/${CHECKSUM_NAME}"
    ;;
esac

echo "Platform: $PLATFORM"
echo "Architecture: $ARCH"
echo "Binary: $BINARY_NAME"
echo "Downloading from: $DOWNLOAD_URL"

# ------------------------------------------------------------------------------
# Download helper
# ------------------------------------------------------------------------------

download_file() {
  url="$1"
  output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${CURL_AUTH[@]}" "$url" -o "$output"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$output" "${WGET_AUTH[@]}" "$url"
  else
    echo "Error: Neither curl nor wget found. Please install one of them." >&2
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# Temporary directory
# ------------------------------------------------------------------------------

TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

TMP_BINARY="$TMP_DIR/$BINARY_NAME"
TMP_CHECKSUM="$TMP_DIR/$CHECKSUM_NAME"

# ------------------------------------------------------------------------------
# Download binary
# ------------------------------------------------------------------------------

if ! download_file "$DOWNLOAD_URL" "$TMP_BINARY"; then
  echo "Error: Failed to download $BINARY_NAME." >&2
  echo "Please check whether this asset exists in the release:" >&2
  echo "  $DOWNLOAD_URL" >&2
  exit 1
fi

if [ ! -s "$TMP_BINARY" ]; then
  echo "Error: Downloaded binary is empty." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Download checksum
# ------------------------------------------------------------------------------

CHECKSUM_AVAILABLE=false

if download_file "$CHECKSUM_URL" "$TMP_CHECKSUM" 2>/dev/null; then
  if [ -s "$TMP_CHECKSUM" ]; then
    CHECKSUM_AVAILABLE=true
  fi
fi

# ------------------------------------------------------------------------------
# Validate checksum
# ------------------------------------------------------------------------------

if [ "$CHECKSUM_AVAILABLE" = true ]; then
  EXPECTED_SHA=""

  # Expected format:
  #   <sha256>  unitarylab-linux-x86_64
  EXPECTED_SHA="$(awk -v name="$BINARY_NAME" '$0 ~ name {print $1; exit}' "$TMP_CHECKSUM")"

  # Fallback: use first hash in the file.
  if [ -z "$EXPECTED_SHA" ]; then
    EXPECTED_SHA="$(awk 'NF >= 1 {print $1; exit}' "$TMP_CHECKSUM")"
  fi

  if [ -z "$EXPECTED_SHA" ]; then
    echo "Error: Could not parse checksum file: $CHECKSUM_NAME" >&2
    exit 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_SHA="$(sha256sum "$TMP_BINARY" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    ACTUAL_SHA="$(shasum -a 256 "$TMP_BINARY" | awk '{print $1}')"
  else
    ACTUAL_SHA=""
    echo "Warning: No sha256sum or shasum found, skipping checksum validation."
  fi

  if [ -n "$ACTUAL_SHA" ]; then
    if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
      echo "Error: Checksum validation failed." >&2
      echo "Expected: $EXPECTED_SHA" >&2
      echo "Actual:   $ACTUAL_SHA" >&2
      exit 1
    fi

    echo "✓ Checksum validated"
  fi
else
  echo "Warning: Checksum file not available. Skipping checksum validation."
fi

# ------------------------------------------------------------------------------
# Validate executable file
# ------------------------------------------------------------------------------

if ! file "$TMP_BINARY" >/dev/null 2>&1; then
  echo "Warning: 'file' command not found, skipping binary type check."
else
  FILE_INFO="$(file "$TMP_BINARY")"

  case "$FILE_INFO" in
    *Mach-O*|*ELF*)
      ;;
    *)
      echo "Error: Downloaded file does not look like a valid macOS/Linux executable." >&2
      echo "$FILE_INFO" >&2
      exit 1
      ;;
  esac
fi

# ------------------------------------------------------------------------------
# Resolve install directory
# ------------------------------------------------------------------------------

if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
  PREFIX="${PREFIX:-/usr/local}"
else
  PREFIX="${PREFIX:-$HOME/.local}"
fi

INSTALL_DIR="$PREFIX/bin"
INSTALL_PATH="$INSTALL_DIR/$CLI_NAME"

if ! mkdir -p "$INSTALL_DIR"; then
  echo "Error: Could not create directory $INSTALL_DIR." >&2
  echo "You may not have write permissions." >&2
  echo "" >&2
  echo "Try one of the following:" >&2
  echo "  sudo bash install.sh" >&2
  echo "  PREFIX=\$HOME/.local bash install.sh" >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Install binary
# ------------------------------------------------------------------------------

if [ -f "$INSTALL_PATH" ]; then
  echo "Notice: Replacing existing binary at $INSTALL_PATH."
fi

TMP_INSTALL_PATH="$INSTALL_DIR/.${CLI_NAME}.tmp.$$"

cp "$TMP_BINARY" "$TMP_INSTALL_PATH"
chmod +x "$TMP_INSTALL_PATH"
mv "$TMP_INSTALL_PATH" "$INSTALL_PATH"

echo "✓ UnitaryLab CLI installed to $INSTALL_PATH"

# ------------------------------------------------------------------------------
# Verify installation
# ------------------------------------------------------------------------------

if [ ! -x "$INSTALL_PATH" ]; then
  echo "Error: Installed file is not executable: $INSTALL_PATH" >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# PATH handling
# ------------------------------------------------------------------------------

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    IN_PATH=true
    ;;
  *)
    IN_PATH=false
    ;;
esac

if [ "$IN_PATH" = false ]; then
  echo ""
  echo "Notice: $INSTALL_DIR is not in your PATH"

  CURRENT_SHELL="$(basename "${SHELL:-/bin/sh}")"

  case "$CURRENT_SHELL" in
    zsh)
      RC_FILE="${ZDOTDIR:-$HOME}/.zprofile"
      PATH_LINE="export PATH=\"$INSTALL_DIR:\$PATH\""
      ;;
    bash)
      if [ -f "$HOME/.bash_profile" ]; then
        RC_FILE="$HOME/.bash_profile"
      elif [ -f "$HOME/.bash_login" ]; then
        RC_FILE="$HOME/.bash_login"
      else
        RC_FILE="$HOME/.profile"
      fi
      PATH_LINE="export PATH=\"$INSTALL_DIR:\$PATH\""
      ;;
    fish)
      RC_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/${CLI_NAME}.fish"
      PATH_LINE="fish_add_path \"$INSTALL_DIR\""
      ;;
    *)
      RC_FILE="$HOME/.profile"
      PATH_LINE="export PATH=\"$INSTALL_DIR:\$PATH\""
      ;;
  esac

  if [ -f "$RC_FILE" ] && grep -F "$INSTALL_DIR" "$RC_FILE" >/dev/null 2>&1; then
    echo "✓ PATH configuration already exists in $RC_FILE"
  elif [ -t 0 ] || [ -e /dev/tty ]; then
    echo ""
    printf "Would you like to add it to %s? [y/N] " "$RC_FILE"

    if read -r REPLY </dev/tty 2>/dev/null; then
      case "$REPLY" in
        y|Y|yes|YES)
          mkdir -p "$(dirname "$RC_FILE")"
          {
            echo ""
            echo "# Added by UnitaryLab installer"
            echo "$PATH_LINE"
          } >> "$RC_FILE"

          echo "✓ Added PATH configuration to $RC_FILE"
          echo "  Restart your shell or run:"
          echo "  source $RC_FILE"
          ;;
        *)
          echo "PATH was not modified."
          ;;
      esac
    fi
  else
    echo ""
    echo "To add $INSTALL_DIR to your PATH permanently, add this to $RC_FILE:"
    echo "  $PATH_LINE"
  fi

  echo ""
  echo "Installation complete! To get started, run:"
  echo "  $PATH_LINE && unitarylab --help"
else
  echo ""
  echo "Installation complete! Run:"
  echo "  unitarylab --help"
fi