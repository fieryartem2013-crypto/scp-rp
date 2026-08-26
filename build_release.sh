#!/usr/bin/env bash
# Сборка релиза SCP RP | DarkRP
#
# Правило: КАЖДЫЙ билд — это НОВЫЙ файл, старые не перезаписываются.
#   ./build_release.sh            собрать текущую версию из VERSION
#   ./build_release.sh --patch    1.0.1 -> 1.0.2 (мини-фикс)
#   ./build_release.sh --minor    1.0.1 -> 1.1.0
#   ./build_release.sh --major    1.0.1 -> 2.0.0
#
# На выходе: SCP_SERVER_v<версия>.zip в корне (старые версии остаются).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/garrysmod/gamemodes/darkrp"
VERSION_FILE="$ROOT/VERSION"

[ -d "$SRC" ] || { echo "Ошибка: нет $SRC" >&2; exit 1; }
[ -f "$VERSION_FILE" ] || { echo "Ошибка: нет $VERSION_FILE" >&2; exit 1; }

VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

bump() {
	local IFS=.
	# shellcheck disable=SC2206
	local parts=($VERSION)
	case "$1" in
		--patch) parts[2]=$(( ${parts[2]:-0} + 1 )) ;;
		--minor) parts[1]=$(( ${parts[1]:-0} + 1 )); parts[2]=0 ;;
		--major) parts[0]=$(( ${parts[0]:-0} + 1 )); parts[1]=0; parts[2]=0 ;;
		*) echo "Неизвестный флаг: $1" >&2; exit 1 ;;
	esac
	VERSION="${parts[0]}.${parts[1]}.${parts[2]}"
	echo "$VERSION" > "$VERSION_FILE"
	echo "Версия повышена до $VERSION"
}

case "${1:-}" in
	--patch|--minor|--major) bump "$1" ;;
	"") : ;;
	*) echo "Использование: $0 [--patch|--minor|--major]" >&2; exit 1 ;;
esac

# Синхронизируем версию в коде гейммода
python3 - "$SRC" "$VERSION" <<'PY'
import re, sys
src, ver = sys.argv[1], sys.argv[2]
for path, pattern, repl in [
    (f"{src}/gamemode/framework/sh_config.lua", r'SCPF\.Version\s*=\s*"[^"]*"', f'SCPF.Version    = "{ver}"'),
    (f"{src}/gamemode/shared.lua",         r'GM\.Version\s*=\s*"[^"]*"',   f'GM.Version = "{ver}"'),
]:
    try:
        s = open(path, encoding="utf-8").read()
        s2 = re.sub(pattern, repl, s, count=1)
        if s2 != s:
            open(path, "w", encoding="utf-8").write(s2)
            print(f"  версия в {path.split('/')[-1]} -> {ver}")
    except FileNotFoundError:
        pass
PY

NAME="SCP_SERVER_v${VERSION}"

# ВАЖНО: старые сборки НЕ удаляем — каждый билд это отдельный файл
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/gamemodes"
cp -r "$SRC" "$STAGE/gamemodes/"
find "$STAGE" -name '.DS_Store' -delete
find "$STAGE" -name '*.zip' -delete

(cd "$STAGE" && zip -qr "$ROOT/${NAME}.zip" gamemodes)

echo "Готово: $ROOT/${NAME}.zip"
echo "Размер: $(du -h "$ROOT/${NAME}.zip" | cut -f1)"
echo "Файлов: $(unzip -l "$ROOT/${NAME}.zip" | tail -1 | awk '{print $2}')"
echo ""
echo "Все сборки:"
ls -1 "$ROOT"/SCP_SERVER_v*.zip 2>/dev/null | sed 's|.*/|  |'
