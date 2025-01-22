#!/bin/bash

# ファイルパスの設定
COUNT_FILE="/home/kiikun0530/joycontrol-pluginloader/regirock/count.txt"
PRECOUNT_FILE="/home/kiikun0530/joycontrol-pluginloader/regirock/precount.txt"
FIND_COLOR_FILE="/home/kiikun0530/joycontrol-pluginloader/regirock/find_color.txt"
WEBHOOK_URL="http://localhost:3000/webhook"

# count.txt から数字を取得
if [[ -f "$COUNT_FILE" ]]; then
    COUNT=$(cat "$COUNT_FILE" | tr -d '\n')
else
    echo "Error: $COUNT_FILE not found."
    exit 1
fi

# precount.txt から数字を取得
if [[ -f "$PRECOUNT_FILE" ]]; then
    PRECOUNT=$(cat "$PRECOUNT_FILE" | tr -d '\n')
else
    PRECOUNT=""
fi

# 比較処理
if [[ "$COUNT" == "$PRECOUNT" ]]; then
    # find_color.txt が存在するか確認
    if [[ -f "$FIND_COLOR_FILE" ]]; then
        echo "find_color.txt exists. No action required."
        exit 0
    else
        # Webhookに「リセット」と送信
        curl -X POST -H "Content-Type: application/json" -d '{"event": {"type": "message", "text": "リセット"}}' "$WEBHOOK_URL"
        echo "Sent 'リセット' to webhook."
    fi
else
    # precount.txt を count.txt の数字で上書き
    echo "$COUNT" > "$PRECOUNT_FILE"
    echo "Updated precount.txt with new count: $COUNT"
fi

exit 0

