#!/bin/bash

set -e  # エラーが発生したらスクリプトを停止

echo "🔧 Raspberry Pi に joycontrol をセットアップ中..."

# 1. 必要なパッケージをインストール
echo "📦 必要なパッケージをインストール中..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip git python3-dbus libhidapi-hidraw0 libbluetooth-dev bluez

# 2. joycontrol / joycontrol-pluginloader をインストール
echo "🎮 joycontrol をインストール中..."
git clone https://github.com/SubstituteDoll/joycontrolpaired.git ~/joycontrol
sudo pip3 install ~/joycontrol

echo "🛠 joycontrol-pluginloader をインストール中..."
git clone --recursive https://github.com/Almtr/joycontrol-pluginloader.git ~/joycontrol-pluginloader
sudo pip3 install ~/joycontrol-pluginloader

# 3. Bluetooth の MAC アドレスを変更
echo "🔄 Bluetooth の MAC アドレスを変更中..."
hciconfig
sudo systemctl stop bluetooth
sudo hcitool -i hci0 cmd 0x3f 0x001 0x56 0x34 0x13 0xCB 0x58 0x94
sudo systemctl start bluetooth
hciconfig  # 変更後の確認

# 4. Bluetooth 設定を変更
echo "🔧 Bluetooth 設定を変更中..."
sudo sed -i 's|ExecStart=/usr/lib/bluetooth/bluetoothd|ExecStart=/usr/lib/bluetooth/bluetoothd --noplugin=input --noplugin=hciuart|' /etc/systemd/system/dbus-org.bluez.service
sudo systemctl daemon-reload
sudo systemctl restart bluetooth

# 5. ngrok をインストール
echo "🌍 ngrok をインストール中..."
wget -q -O ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip
unzip ngrok.zip
chmod +x ngrok
sudo mv ngrok /usr/local/bin/
rm ngrok.zip
ngrok authtoken <YOUR_NGROK_AUTHTOKEN>

# 6. ngrok の認証トークンを設定 (手動で変更必要)
echo "🔑 ngrok の認証トークンを設定してください！"
echo "以下のコマンドを実行してください："
echo "    ngrok authtoken <YOUR_NGROK_AUTHTOKEN>"
echo "認証トークンを取得するには、 https://dashboard.ngrok.com/get-started/setup にアクセスしてください。"

echo "✅ セットアップ完了！"
