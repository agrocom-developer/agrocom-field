#!/bin/bash
# bin/bump-version.sh — Script para incrementar versión SemVer + versionCode
# Uso: ./bin/bump-version.sh {major|minor|patch}
#
# Modifica pubspec.yaml (versión + versionCode)
# Retorna: "vX.Y.Z+N" si éxito, sale con exit 1 si error

set -euo pipefail

BUMP_TYPE="${1:-patch}"

# Valida input
case "$BUMP_TYPE" in
  major|minor|patch) ;;
  *)
    echo "Error: bump-type debe ser major, minor o patch (recibido: $BUMP_TYPE)" >&2
    exit 1
    ;;
esac

# Lee pubspec.yaml
PUBSPEC_YAML="pubspec.yaml"
if [[ ! -f "$PUBSPEC_YAML" ]]; then
  echo "Error: no se encontró $PUBSPEC_YAML" >&2
  exit 1
fi

# Parsea versión actual (formato: version: X.Y.Z+N)
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_YAML" | sed 's/version: //')
CURRENT_SEMVER=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
CURRENT_VERSIONCODE=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

if [[ -z "$CURRENT_SEMVER" || -z "$CURRENT_VERSIONCODE" ]]; then
  echo "Error: no se pudo parsear versión de $PUBSPEC_YAML (actual: $CURRENT_VERSION)" >&2
  exit 1
fi

# Separa major.minor.patch
MAJOR=$(echo "$CURRENT_SEMVER" | cut -d'.' -f1)
MINOR=$(echo "$CURRENT_SEMVER" | cut -d'.' -f2)
PATCH=$(echo "$CURRENT_SEMVER" | cut -d'.' -f3)

# Calcula nueva versión
case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_SEMVER="$MAJOR.$MINOR.$PATCH"
NEW_VERSIONCODE=$((CURRENT_VERSIONCODE + 1))
NEW_VERSION="$NEW_SEMVER+$NEW_VERSIONCODE"

# Valida que versionCode no se reutilice (sanity check)
if [[ $NEW_VERSIONCODE -le $CURRENT_VERSIONCODE ]]; then
  echo "Error: versionCode no puede permanecer igual o disminuir (era $CURRENT_VERSIONCODE, nuevo: $NEW_VERSIONCODE)" >&2
  exit 1
fi

# Actualiza pubspec.yaml
sed -i "" "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_YAML"

# Verifica cambio
UPDATED_VERSION=$(grep "^version:" "$PUBSPEC_YAML" | sed 's/version: //')
if [[ "$UPDATED_VERSION" != "$NEW_VERSION" ]]; then
  echo "Error: sed no actualizó pubspec.yaml correctamente" >&2
  echo "  esperado: $NEW_VERSION" >&2
  echo "  actual: $UPDATED_VERSION" >&2
  exit 1
fi

# Retorna la versión nueva
echo "v$NEW_VERSION"
exit 0
