#!/bin/bash

# find_color.txtが存在する場合、削除する
if [[ -f "/home/kiikun0530/joycontrol-pluginloader/regirock/find_color.txt" ]]; then
  echo "find_color.txt を削除します..."
  rm -f /home/kiikun0530/joycontrol-pluginloader/regirock/find_color.txt
else
  echo "find_color.txt は存在しません。"
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
