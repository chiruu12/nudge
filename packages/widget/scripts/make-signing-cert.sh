#!/usr/bin/env bash
set -euo pipefail

# Creates a self-signed code-signing identity ("Nudge Dev") in the login
# keychain so rebuilds keep a STABLE signature — macOS then preserves the
# microphone permission grant across `make app` instead of re-prompting.
#
# This is NOT notarization: distributed apps still need the right-click -> Open
# Gatekeeper step. It only stabilizes local signing identity.
#
# Idempotent: re-running is a no-op once the identity exists.
# Run once: make signing-cert

IDENTITY="Nudge Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
  echo "Signing identity '$IDENTITY' already exists — nothing to do."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/cert.cfg" <<EOF
[ req ]
distinguished_name = dn
x509_extensions = ext
prompt = no
[ dn ]
CN = $IDENTITY
[ ext ]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -days 3650 -config "$TMP/cert.cfg" >/dev/null 2>&1

openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -out "$TMP/identity.p12" -passout pass:nudge -name "$IDENTITY" >/dev/null 2>&1

# Import the identity and authorize codesign to use the private key.
security import "$TMP/identity.p12" -k "$KEYCHAIN" -P nudge \
  -T /usr/bin/codesign -T /usr/bin/security

# Best-effort: avoid a keychain prompt on first codesign use. Harmless if it
# fails (you'll just click "Always Allow" once).
security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
  -k "" "$KEYCHAIN" >/dev/null 2>&1 || true

echo "Created signing identity '$IDENTITY'."
echo "Now run: make app   (it will sign with this identity automatically)"
