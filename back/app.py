from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import json
import os
from datetime import datetime
from dotenv import load_dotenv
import google.generativeai as genai
import requests
import base64
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)  # CORSを有効化

# データ保存用のディレクトリ
DATA_DIR = "data"
PROFILE_FILE = os.path.join(DATA_DIR, "profile.json")
UPLOAD_DIR = os.path.join(DATA_DIR, "uploads")
GENERATED_DIR = os.path.join(DATA_DIR, "generated")

# データディレクトリがなければ作成
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)
if not os.path.exists(GENERATED_DIR):
    os.makedirs(GENERATED_DIR)

# .envを読み込む
load_dotenv(override=True)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY is not set")

genai.configure(api_key=GEMINI_API_KEY)

# Stable Diffusion API URL
SD_API_URL = "https://saliently-multiciliated-jacqui.ngrok-free.dev/sdapi/v1"

def trivia_trueorfalse(trivia: str):
    model = genai.GenerativeModel("models/gemini-2.5-flash")
    prompt = f"""
あなたはファクトチェッカーです。
以下の文が事実として正しいかどうかを判断してください。

【ルール】
・出力は True または False のみ
・理由、説明、補足は禁止
・改行や空白も不要
・あなたの一般的・学術的知識に基づいて判断すること

【検証対象】
{trivia}
"""
    response = model.generate_content(prompt)
    text = response.text.strip()

    if text == "True":
        return True
    if text == "False":
        return False
    return None

@app.route('/save_profile', methods=['POST'])
def save_profile():
    try:
        # multipart/form-dataから取得
        nickname = request.form.get('nickname')
        birthday = request.form.get('birthday')
        birthplace = request.form.get('birthplace')
        trivia = request.form.get('trivia')
        user_id = request.form.get('id')
        ver = request.form.get('ver')
        
        if not nickname or not trivia:
            return jsonify({"error": "nickname と trivia は必須です"}), 400
        
        # 画像ファイルの処理
        image_path = None
        if 'img' in request.files:
            file = request.files['img']
            if file.filename:
                filename = secure_filename(f"{user_id}_{datetime.now().timestamp()}.png")
                image_path = os.path.join(UPLOAD_DIR, filename)
                file.save(image_path)
        
        # Trivia判定
        trivia_result = trivia_trueorfalse(trivia)
        
        # データ保存
        data = {
            'nickname': nickname,
            'birthday': birthday,
            'birthplace': birthplace,
            'trivia': trivia,
            'trivia_result': trivia_result,
            'user_id': user_id,
            'ver': ver,
            'image_path': image_path,
            'saved_at': datetime.now().isoformat()
        }
        
        with open(PROFILE_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        return jsonify({
            "message": "プロフィールを保存しました",
            "data": data
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get_profile', methods=['GET'])
def get_profile():
    try:
        if not os.path.exists(PROFILE_FILE):
            return jsonify({"message": "プロフィールが見つかりません"}), 404
        
        with open(PROFILE_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return jsonify(data), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/generate_image', methods=['POST'])
def generate_image():
    try:
        trivia = request.form.get('trivia')
        user_id = request.form.get('id', 'unknown')
        
        if not trivia:
            return jsonify({"error": "trivia は必須です"}), 400
        
        # Geminiでプロンプト生成
        model = genai.GenerativeModel("models/gemini-2.5-flash")
        response = model.generate_content(
            trivia + "\n以下のルールに従ってください：\n"
            "・出力は1行のテキストのみ\n"
            "・余計な文章や返事は一切不要\n"
            "・コンマ区切りの英単語でAIにコピペ可能な形\n"
            "・必ず以下の単語を含める：Hand-drawn, Deformed, Pastel colors"
        )
        
        prompt = response.text.strip()
        
        # Stable Diffusion API呼び出し
        payload = {
            "prompt": prompt,
            "negative_prompt": (
                "low quality, worst quality, blurry, grainy, pixelated, jpeg artifacts, "
                "bad anatomy, deformed, extra limbs, missing limbs, wrong hands, "
                "malformed face, text, logo, watermark, signature, username, "
                "nsfw, nudity, gore, violence, overexposed, oversaturated, ugly"
            ),
            "steps": 35,
            "width": 512,
            "height": 512
        }
        
        r = requests.post(
            f"{SD_API_URL}/txt2img",
            json=payload,
            timeout=180
        )
        r.raise_for_status()
        
        img_base64 = r.json()["images"][0]
        img_bytes = base64.b64decode(img_base64)
        
        # 画像を保存
        filename = f"{user_id}_{datetime.now().timestamp()}_generated.png"
        image_path = os.path.join(GENERATED_DIR, filename)
        with open(image_path, 'wb') as f:
            f.write(img_bytes)
        
        # 画像URLを返す（実際には画像パスまたはbase64を返す）
        return jsonify({
            "message": "画像を生成しました",
            "image_url": f"/get_image/{filename}",
            "image_base64": f"data:image/png;base64,{img_base64}"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/img2img', methods=['POST'])
def img2img():
    try:
        user_id = request.form.get('id', 'unknown')
        
        # 画像ファイルの取得
        if 'img' not in request.files:
            return jsonify({"error": "画像ファイルが必要です"}), 400
        
        file = request.files['img']
        if not file.filename:
            return jsonify({"error": "画像ファイルが必要です"}), 400
        
        # 画像をbase64に変換
        img_bytes = file.read()
        img_base64 = base64.b64encode(img_bytes).decode('utf-8')
        
        # デフォルトプロンプト（または最後に生成したプロンプトを使用）
        prompt = "Hand-drawn, Deformed, Pastel colors, portrait"
        
        # Stable Diffusion img2img API呼び出し
        payload = {
            "init_images": [img_base64],
            "prompt": prompt,
            "negative_prompt": (
                "low quality, worst quality, blurry, grainy, pixelated, jpeg artifacts, "
                "bad anatomy, extra limbs, missing limbs, wrong hands, malformed face, "
                "text, logo, watermark, signature, username, nsfw, nudity, gore, violence"
            ),
            "denoising_strength": 0.55,
            "steps": 35,
            "width": 512,
            "height": 512
        }
        
        r = requests.post(
            f"{SD_API_URL}/img2img",
            json=payload,
            timeout=180
        )
        r.raise_for_status()
        
        result_base64 = r.json()["images"][0]
        result_bytes = base64.b64decode(result_base64)
        
        # 画像を保存
        filename = f"{user_id}_{datetime.now().timestamp()}_img2img.png"
        image_path = os.path.join(GENERATED_DIR, filename)
        with open(image_path, 'wb') as f:
            f.write(result_bytes)
        
        return jsonify({
            "message": "画像変換が完了しました",
            "image_url": f"/get_image/{filename}",
            "image_base64": f"data:image/png;base64,{result_base64}"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get_image/<filename>', methods=['GET'])
def get_image(filename):
    try:
        image_path = os.path.join(GENERATED_DIR, filename)
        if os.path.exists(image_path):
            return send_file(image_path, mimetype='image/png')
        return jsonify({"error": "画像が見つかりません"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
