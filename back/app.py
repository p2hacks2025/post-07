from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from datetime import datetime
from dotenv import load_dotenv
import google.generativeai as genai

app = Flask(__name__)
CORS(app)  # CORSを有効化

# データ保存用のディレクトリ
DATA_DIR = "data"
PROFILE_FILE = os.path.join(DATA_DIR, "profile.json")

# データディレクトリがなければ作成
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

# .envを読み込む
load_dotenv(override=True)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY is not set")

genai.configure(api_key=GEMINI_API_KEY)

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
        data = request.get_json()
        if not data:
            return jsonify({"error": "データが送信されていません"}), 400
        
        required_fields = ['nickname', 'birthday', 'birthplace', 'trivia']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"{field}が見つかりません"}), 400
        
        # Trivia判定
        trivia_result = trivia_trueorfalse(data['trivia'])
        data['trivia_result'] = trivia_result

        # タイムスタンプを追加
        data['saved_at'] = datetime.now().isoformat()
        
        # ファイルに保存
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

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
