#!/bin/bash

# find_color.txtが存在する場合、削除する
if [[ -f "/home/kiikun0530/joycontrol-pluginloader/regirock/find_color.txt" ]]; then
  echo "find_color.txt を削除します..."
  rm -f /home/kiikun0530/joycontrol-pluginloader/regirock/find_color.txt
else
  echo "find_color.txt は存在しません。"
fi



echo "filename.txt からファイル名を取得します..."

if [[ -f /home/kiikun0530/joycontrol-pluginloader/regirock/filename.txt ]]; then
  FILENAME=$(head -n 1 /home/kiikun0530/joycontrol-pluginloader/regirock/filename.txt)
  if [[ -n "$FILENAME" ]]; then
    echo "取得したファイル名: $FILENAME"

    if [[ -f /home/kiikun0530/joycontrol-pluginloader/regirock/image_number.txt ]]; then
      CURRENT_NUMBER=$(head -n 1 /home/kiikun0530/joycontrol-pluginloader/regirock/image_number.txt)
      if [[ "$CURRENT_NUMBER" =~ ^[0-9]+$ ]]; then
        NEW_NUMBER=$((CURRENT_NUMBER + 1))
        NEW_FILENAME="/home/kiikun0530/joycontrol-pluginloader/regirock/regirock_${NEW_NUMBER}.jpg"

        sudo mv "$FILENAME" "$NEW_FILENAME"
        echo "$FILENAME を $NEW_FILENAME に変更しました。"

        echo "$NEW_NUMBER" | sudo tee /home/kiikun0530/joycontrol-pluginloader/regirock/image_number.txt > /dev/null
        echo "image_number.txt を $NEW_NUMBER に更新しました。"
      else
        echo "image_number.txt の内容が無効です。数字が必要です。"
      fi
    else
      echo "image_number.txt が見つかりません。"
    fi
  else
    echo "filename.txt の1行目が空です。"
  fi
else
  echo "filename.txt が見つかりません。"
fi

# pokecolor.sh が動作している場合、停止する
echo "pokecolor.sh が動作しているか確認します..."
PIDS=$(sudo pgrep -f "bash .*pokecolor.sh")

if [[ -n "$PIDS" ]]; then
  echo "pokecolor.sh を停止します..."
  sudo kill $PIDS 2>/dev/null || true
  echo "pokecolor.sh を停止しました。"
else
  echo "pokecolor.sh は動作していません。"
fi

sudo joycontrol-pluginloader -r 98:41:5C:86:62:4E /home/kiikun0530/joycontrol-pluginloader/plugins/samples/ResetPokeColor.py
echo "pokecolor.shのリセットが完了しました"

echo "pokecolor.sh をバックグラウンドで起動します..."
sudo bash /home/kiikun0530/joycontrol-pluginloader/pokecolor.sh
echo "pokecolor.sh を起動しました（PID: $!）。"
