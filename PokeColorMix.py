import logging
import aiofiles
import numpy as np
import os
import cv2
from datetime import datetime
from JoycontrolPlugin import JoycontrolPlugin
import sys

logger = logging.getLogger(__name__)

def capture_image(output_file):
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        logger.info("Error: Could not open camera.")
        return
    ret, frame = cap.read()
    if ret:
        cv2.imwrite(output_file, frame)
        logger.info(f"Image saved as {output_file}")
    else:
        logger.info("Error: Could not capture image.")
    cap.release()

def preprocess_image(image):
    """
    画像をLAB色空間に変換し、aチャンネルとbチャンネルを抽出
    """
    lab_image = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    a_channel, b_channel = lab_image[:, :, 1], lab_image[:, :, 2]
    return a_channel, b_channel

def calculate_histogram(image_a, image_b, bins=100):
    """
    aチャンネルとbチャンネルのヒストグラムを計算して正規化し、結合する
    """
    hist_a = cv2.calcHist([image_a], [0], None, [bins], [0, 256])
    hist_b = cv2.calcHist([image_b], [0], None, [bins], [0, 256])

    cv2.normalize(hist_a, hist_a)
    cv2.normalize(hist_b, hist_b)

    return hist_a + hist_b

def is_other_color(nowimage, baseimage_hist):
    """
    画像のヒストグラムを比較し、色違いかどうか判定する
    """
    # 前処理でLAB色空間のaチャンネルとbチャンネルを抽出
    nowimage_a, nowimage_b = preprocess_image(nowimage)

    # ヒストグラムを計算
    nowimage_hist = calculate_histogram(nowimage_a, nowimage_b)

    # バタチャリヤ距離を計算（0に近いほど類似、1に近いほど異なる）
    distance = cv2.compareHist(baseimage_hist, nowimage_hist, cv2.HISTCMP_BHATTACHARYYA)

    # ヒストグラムの差分を計算（L2ノルム）
    diff = cv2.absdiff(baseimage_hist, nowimage_hist)
    diff_score = np.linalg.norm(diff)

    logging.info(f"Bhattacharyya Distance: {distance:.4f}, Histogram Diff Score: {diff_score:.4f}")

    # 色違い判定（バタチャリヤ距離と差分スコアの両方で判断）
    return distance > 0.3 or diff_score > 0.1


SLACK_BOT_TOKEN = "xoxb-8308376948400-8282787066149-EQwEM5nBphUZMHJFN1AAmJ6T"
CHANNEL_ID = "C088S7W6PLH"
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
# Slackクライアントの初期化
client = WebClient(token=SLACK_BOT_TOKEN)

def send_message_to_slack(message):
    """Slackにメッセージを送信"""
    try:
        response = client.chat_postMessage(
            channel=CHANNEL_ID,
            text=message
        )
        logger.info("メッセージを送信しました: ", response["ts"])
    except SlackApiError as e:
        logger.info(f"メッセージの送信に失敗しました: {e.response['error']}")

def upload_image_to_slack(file_path, title):
    """Slackに画像をアップロード"""
    try:
        response = client.files_upload_v2(
            channels=CHANNEL_ID,
            file=file_path,
            title=title
        )
        logger.info("画像をアップロードしました: ", response["file"]["id"])
    except SlackApiError as e:
        logger.info(f"画像のアップロードに失敗しました: {e.response['error']}")

message = "色違いが出現したかも"

def create_done_file():
    try:
        with open('/home/kiikun0530/joycontrol-pluginloader/regirock/find_color.txt', 'w') as file:
            pass
        logger.info("find_color.txt has been created")
    except Exception as e:
        logger.info(f'An error occurred while creating the file: {e}')

def record_filename(filename):
    """
    Writes the given filename to the first line of a file named filename.txt.
    If the file already exists, it overwrites the first line.
    """
    try:
        with open("/home/kiikun0530/joycontrol-pluginloader/regirock/filename.txt", "w") as file:
            file.write(filename + "\n")
    except Exception as e:
        logger.info(f"An error occurred: {e}")


def load_or_compute_histogram(image_path, hist_path, bins=100):
    """
    画像のヒストグラムをキャッシュとして保存し、次回以降はキャッシュを使用する
    """
    if os.path.exists(hist_path):
        # キャッシュからヒストグラムをロード
        hist = np.load(hist_path)
        logger.info(f"Loaded histogram from cache: {hist_path}")
    else:
        # 画像を読み込んでヒストグラムを計算
        image = cv2.imread(image_path, cv2.IMREAD_COLOR)
        if image is None:
            logging.error(f"Failed to read image: {image_path}")
            return None
        
        image_a, image_b = preprocess_image(image)
        hist = calculate_histogram(image_a, image_b, bins)

        # ヒストグラムを保存
        np.save(hist_path, hist)
        logger.info(f"Saved histogram to cache: {hist_path}")
    return hist

class PokeColorMix(JoycontrolPlugin):
    async def read_and_increment_count(self):
        count = 0
        try:
            async with aiofiles.open('/home/kiikun0530/joycontrol-pluginloader/regirock/count.txt', 'r') as f:
                content = await f.readline()
                count = int(content.strip()) + 1
        except FileNotFoundError:
            count = 1
        except ValueError:
            count = 1  # ファイルの値が不正な場合は1から開始
        async with aiofiles.open('/home/kiikun0530/joycontrol-pluginloader/regirock/count.txt', 'w') as f:
            await f.write(str(count) + '\n')
        return count

    async def run(self):
        logger.info('This is PokeColor')
        while True:
            count = await self.read_and_increment_count()
            logger.info(f'Current count: {count}')
            await self.button_push('a')
            await self.wait(1)
            await self.button_push('a')
            await self.wait(12.8)
            await self.button_push('a')
            await self.wait(3.5)
            await self.button_push('a')
            await self.wait(0.5)
            await self.button_push('a')
            await self.wait(0.5)
            await self.button_push('a')
            await self.wait(7.5)
            logger.info('Capture Image')
            filename = f"/home/kiikun0530/joycontrol-pluginloader/regirock/temp-{datetime.now().strftime('%Y%m%d-%H%M%S')}.jpg" 
            capture_image(filename)
            filename_image = cv2.imread(filename, cv2.IMREAD_COLOR)
            # image_number.txtから番号を読み取る
            image_number = 0
            with open('/home/kiikun0530/joycontrol-pluginloader/regirock/image_number.txt', 'r') as file:
                image_number = int(file.readline().strip())
               # ベース画像パスを動的に生成
            is_the_same_color = False
            for i in range(image_number + 1):
                baseimage_path = f'/home/kiikun0530/joycontrol-pluginloader/regirock/regirock_{i}.jpg'
                hist_path = f'/home/kiikun0530/joycontrol-pluginloader/regirock/regirock_{i}_hist.npy'
    
                baseimage_hist = load_or_compute_histogram(baseimage_path, hist_path)
                if baseimage_hist is None:
                    continue
                if not is_other_color(filename_image, baseimage_hist):
                    is_the_same_color = True
                    break
            if not is_the_same_color:
                record_filename(filename)
                logger.info('色違い出現！')
                create_done_file()
                send_message_to_slack(message)
                upload_image_to_slack(filename, "色違い画像")
                input("無限待機中です。Ctrl+Cで終了してください。\n")
            os.remove(filename)
            await self.button_push('home')
            await self.wait(0.5)
            await self.button_push('x')
            await self.wait(0.3)
            await self.button_push('a')
            await self.wait(3)
