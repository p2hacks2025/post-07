from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)  # CORSを有効化

# データ保存用のディレクトリ
DATA_DIR = "data"
PROFILE_FILE = os.path.join(DATA_DIR, "profile.json")

# データディレクトリがなければ作成
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

@app.route('/save_profile', methods=['POST'])
def save_profile():
    try:
        # リクエストからデータを取得
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "データが送信されていません"}), 400
        
        # 必須フィールドの確認
        required_fields = ['nickname', 'birthday', 'birthplace', 'trivia']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"{field}が見つかりません"}), 400
        
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
        # プロフィールファイルが存在するか確認
        if not os.path.exists(PROFILE_FILE):
            return jsonify({"message": "プロフィールが見つかりません"}), 404
        
        # ファイルからデータを読み込み
        with open(PROFILE_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return jsonify(data), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    # ngrokと連携する場合は0.0.0.0で起動
    app.run(host='0.0.0.0', port=5000, debug=True)
