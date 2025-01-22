const express = require('express');
const { spawn } = require('child_process');
const app = express();
const bodyParser = require('body-parser');

app.use(bodyParser.json());

// Webhookエンドポイント
app.post('/webhook', (req, res) => {
    const body = req.body;

    // Slackのチャレンジリクエストに対応
    if (body.type === 'url_verification') {
        return res.status(200).json({ challenge: body.challenge });
    }

    // Slackイベント処理
    if (body.event && body.event.type === 'message') {
        const event = body.event;

        // メッセージが「リセット」かどうかを確認
        if (event.text === 'リセット') {
            console.log('リセットが送信されました');

            // 必要に応じてスクリプトを実行
            const script = spawn('sudo', ['bash', '/home/kiikun0530/joycontrol-pluginloader/resetfromline.sh'], {
                stdio: 'inherit', // 親プロセスの標準入出力を継承
            });

            script.on('close', (code) => {
                console.log(`resetfromline.sh が終了しました (コード: ${code})`);
            });

            script.on('error', (err) => {
                console.error(`resetfromline.sh 実行中にエラーが発生しました: ${err.message}`);
            });
        } else if (event.text === 'アド') {
            console.log('アドが送信されました');

            // スワップスクリプトを実行
            const script = spawn('sudo', ['bash', '/home/kiikun0530/joycontrol-pluginloader/addreset.sh'], {
                stdio: 'inherit', // 親プロセスの標準入出力を継承
            });

            script.on('close', (code) => {
                console.log(`addreset.sh が終了しました (コード: ${code})`);
            });

            script.on('error', (err) => {
                console.error(`addreset.sh 実行中にエラーが発生しました: ${err.message}`);
            });
        } else {
            console.log(`メッセージを受信しました: ${event.text}`);
        }
    }

    // 正常終了のレスポンス
    res.sendStatus(200);
});

// サーバーを起動
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

