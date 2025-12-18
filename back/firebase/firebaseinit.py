import firebase_admin
from firebase_admin import credentials, firestore

# サービスアカウントキーのパス
cred = credentials.Certificate("p2hacks.json")

# Firebase Admin SDK 初期化
firebase_admin.initialize_app(cred)

# Firestore クライアント取得
db = firestore.client()
