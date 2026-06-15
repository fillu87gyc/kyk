#!/usr/bin/env bash
# deploy.sh — Steam Deck へのヘッドレスエクスポート＆転送スクリプト
#
# 使用例:
#   ./deploy.sh                         # エクスポートのみ
#   DECK_HOST=deck ./deploy.sh          # エクスポート＋SCP転送
#   DECK_HOST=deck DECK_RUN=1 ./deploy.sh  # 転送後に実機起動

set -euo pipefail

GODOT="${GODOT:-godot}"
BUILD_DIR="build"
BINARY_NAME="kouya-kou.x86_64"
PRESET_NAME="Linux (Steam Deck)"

DECK_HOST="${DECK_HOST:-}"
DECK_USER="${DECK_USER:-deck}"
DECK_PATH="${DECK_PATH:-/home/deck/games/kouya-kou}"
DECK_RUN="${DECK_RUN:-0}"

echo "=== 紅夜航 Steam Deck Deploy ==="

# --- エクスポートテンプレート確認 ---
if ! command -v "$GODOT" &>/dev/null; then
  echo "[ERROR] Godot が見つかりません: $GODOT"
  echo "  export GODOT=/path/to/godot4"
  exit 1
fi

mkdir -p "$BUILD_DIR"

# --- headless エクスポート ---
echo "[1/3] エクスポート中: $PRESET_NAME"
"$GODOT" --headless \
  --export-release "$PRESET_NAME" \
  "$BUILD_DIR/$BINARY_NAME" \
  2>&1 | grep -v "^$"

if [[ ! -f "$BUILD_DIR/$BINARY_NAME" ]]; then
  echo "[ERROR] エクスポート失敗: $BUILD_DIR/$BINARY_NAME が存在しません"
  exit 1
fi

chmod +x "$BUILD_DIR/$BINARY_NAME"
echo "[1/3] 完了: $BUILD_DIR/$BINARY_NAME"

# --- Steam Deck 転送 ---
if [[ -z "$DECK_HOST" ]]; then
  echo "[2/3] DECK_HOST 未設定 — 転送をスキップ"
  echo "  転送するには: DECK_HOST=<IP> ./deploy.sh"
  exit 0
fi

echo "[2/3] Steam Deck へ転送: $DECK_USER@$DECK_HOST:$DECK_PATH"
ssh "$DECK_USER@$DECK_HOST" "mkdir -p $DECK_PATH"
scp "$BUILD_DIR/$BINARY_NAME" "$DECK_USER@$DECK_HOST:$DECK_PATH/"

echo "[2/3] 完了"

# --- 実機起動 ---
if [[ "$DECK_RUN" == "1" ]]; then
  echo "[3/3] 実機起動"
  ssh "$DECK_USER@$DECK_HOST" \
    "cd $DECK_PATH && chmod +x $BINARY_NAME && ./$BINARY_NAME"
else
  echo "[3/3] スキップ (DECK_RUN=1 で起動)"
fi

echo "=== 完了 ==="
