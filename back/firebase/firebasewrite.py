import json
import firebase_admin
from firebase_admin import credentials, firestore

# =========================
# Firebase 初期化
# =========================
SERVICE_ACCOUNT_PATH = "p2hacks.json"  # JSONの名前を変えてもOK
cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred)

db = firestore.client()

# =========================
# JSON ファイル読み込み
# =========================
JSON_DATA_PATH = "data.json"  # 書き込みたいJSONファイル

with open(JSON_DATA_PATH, "r", encoding="utf-8") as f:
    data_list = json.load(f)  # JSON はリスト形式が推奨
    # 例: [{"name": "Taro", "age": 25}, {"name": "Hanako", "age": 30}]

# =========================
# Firestore に書き込み
# =========================
def write_to_firestore(collection_name: str, data_list: list):
    collection_ref = db.collection(collection_name)
    for data in data_list:
        # ドキュメントIDを自動生成して追加
        doc_ref = collection_ref.add(data)
        print(f"Added document with ID: {doc_ref[1].id}")

# =========================
# 実行
# =========================
if __name__ == "__main__":
    write_to_firestore("users", data_list)
