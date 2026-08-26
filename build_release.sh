#!/usr/bin/env bash
# Сборка релиза SCP RP | DarkRP
# Формат имени: SCP_SERVER_v<версия>.zip
set -euo pipefail

VERSION="1.0.0"
NAME="SCP_SERVER_v${VERSION}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/garrysmod/gamemodes/darkrp"

[ -d "$SRC" ] || { echo "Ошибка: нет $SRC" >&2; exit 1; }

# Чистим старые сборки
rm -f "$ROOT"/SCP_SERVER_v*.zip
rm -rf "$ROOT/dist"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/gamemodes"
cp -r "$SRC" "$STAGE/gamemodes/"
find "$STAGE" -name '.DS_Store' -delete
find "$STAGE" -name '*.zip' -delete

# Внутри архива: gamemodes/darkrp/... → распаковывать в папку garrysmod/
(cd "$STAGE" && zip -qr "$ROOT/${NAME}.zip" gamemodes)

echo "Готово: $ROOT/${NAME}.zip"
echo "Размер: $(du -h "$ROOT/${NAME}.zip" | cut -f1)"
echo "Файлов: $(unzip -l "$ROOT/${NAME}.zip" | tail -1 | awk '{print $2}')"
