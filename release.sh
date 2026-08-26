#!/usr/bin/env bash
# Полный цикл релиза: bump версии -> проверка -> сборка -> коммит -> пуш на GitHub
#
# Использование:
#   ./release.sh --patch "описание фикса"
#   ./release.sh --minor "описание"
#
# Токен GitHub берётся из переменной окружения GH_TOKEN:
#   GH_TOKEN=github_pat_... ./release.sh --patch "описание"
#
# Токен НЕ пишется ни в один файл и не сохраняется в git remote.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO="$ROOT/repo"
REMOTE_URL="github.com/fieryartem2013-crypto/scp-rp.git"
OWNER="fieryartem2013-crypto"

BUMP="${1:---patch}"
MSG="${2:-обновление}"

case "$BUMP" in
	--patch|--minor|--major) ;;
	*) echo "Использование: $0 [--patch|--minor|--major] \"описание\"" >&2; exit 1 ;;
esac

echo "=== 1. Проверка синтаксиса Lua ==="
if python3 "$ROOT/check_lua.py" | tail -2; then
	python3 "$ROOT/check_lua.py" >/dev/null || { echo "Синтаксические ошибки — релиз отменён" >&2; exit 1; }
fi

echo ""
echo "=== 2. Сборка ==="
"$ROOT/build_release.sh" "$BUMP"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"

echo ""
echo "=== 3. Синхронизация репозитория ==="
[ -d "$REPO/.git" ] || { echo "Нет $REPO — склонируй сначала" >&2; exit 1; }
rm -rf "$REPO/garrysmod/gamemodes/darkrp"
mkdir -p "$REPO/garrysmod/gamemodes"
cp -r "$ROOT/garrysmod/gamemodes/darkrp" "$REPO/garrysmod/gamemodes/"
cp "$ROOT/build_release.sh" "$REPO/"
cp "$ROOT/release.sh" "$REPO/" 2>/dev/null || true
cp "$ROOT/check_lua.py" "$REPO/tools_check_lua.py" 2>/dev/null || true
cp "$ROOT/VERSION" "$REPO/"

echo ""
echo "=== 4. Коммит ==="
cd "$REPO"
git add -A
if git diff --cached --quiet; then
	echo "Изменений нет — коммит не создан"
else
	git -c user.name="SCP Server" -c user.email="scp-server@users.noreply.github.com" \
		commit -q -m "v${VERSION}: ${MSG}"
	echo "Коммит: $(git log --oneline -1)"
fi

echo ""
echo "=== 5. Пуш на GitHub ==="
if [ -z "${GH_TOKEN:-}" ]; then
	echo "GH_TOKEN не задан — пропускаю пуш."
	echo "Запусти так:  GH_TOKEN=github_pat_... ./release.sh --patch \"описание\""
	exit 0
fi

git push "https://${OWNER}:${GH_TOKEN}@${REMOTE_URL}" main 2>&1 \
	| sed "s/${GH_TOKEN}/<TOKEN>/g"

echo ""
echo "=== Готово: v${VERSION} ==="
echo "GitHub: https://github.com/${OWNER}/scp-rp"
echo "Файл:   $ROOT/SCP_SERVER_v${VERSION}.zip"
