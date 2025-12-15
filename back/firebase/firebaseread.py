import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT_PATH = "p2hacks.json"  # 必要に応じて名前を変更

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred)

# Firestore クライアント取得
db = firestore.client()

# =========================
# データ取得関数
# =========================
def get_users():
    """
    'users' コレクションの全ドキュメントを取得して
    リストで返す
    """
    users_ref = db.collection("p2hacks2025")
    docs = users_ref.stream()

    users = []
    for doc in docs:
        data = doc.to_dict()
        data['id'] = doc.id  # ドキュメントIDも追加
        users.append(data)
    
    return users

# =========================
# 実行例
# =========================
if __name__ == "__main__":
    all_users = get_users()
    for user in all_users:
        print(user)
