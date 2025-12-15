import firebase_admin
from firebase_admin import credentials, firestore, storage

# 初期化状態を管理する変数
_db = None
_bucket = None

def initialize():
    """Firebaseを初期化し、DBとBucketへの接続を確立する"""
    global _db, _bucket
    
    # すでに初期化済みなら何もしない（二重初期化防止）
    if not firebase_admin._apps:
        # 鍵ファイルの読み込み
        cred = credentials.Certificate("serviceAccountKey.json")
        
        # 初期化（バケット名は自分のものに書き換えてください！）
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'hakodate-ar-2025.firebasestorage.app' 
        })
        
        _db = firestore.client()
        _bucket = storage.bucket()
        print("--- Firebase Connected ---")
    else:
        _db = firestore.client()
        _bucket = storage.bucket()

def get_db():
    return _db

def get_bucket():
    return _bucket