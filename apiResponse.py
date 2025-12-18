from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import datetime
import io
from PIL import Image

# データベース接続用ファイルをインポート
import databaseConnect

app = FastAPI()

# --- 1. Firebase接続 (サーバー起動時に実行) ---
databaseConnect.initialize()
db = databaseConnect.get_db()
bucket = databaseConnect.get_bucket()

# --- 2. CORS設定 ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 3. データモデル (フロントエンドからのデータ形式) ---
class UserProfile(BaseModel):
    nickname: str
    birthday: str
    birthplace: str
    trivia: str

# --- 4. メイン処理 ---
@app.post("/save_profile")
def save_profile(profile: UserProfile):
    try:
        print(f"受信データ: {profile.nickname}")

        # -------------------------------------------------
        # Step A: 画像データの準備 (一旦ダミー画像)
        # -------------------------------------------------
        # ※ Gemini APIキーがまだ設定されていないため、動作確認用に青い画像を生成します
        dummy_img = Image.new('RGB', (600, 400), color=(73, 109, 137))
        img_byte_arr = io.BytesIO()
        dummy_img.save(img_byte_arr, format='PNG')
        image_bytes = img_byte_arr.getvalue()

        # -------------------------------------------------
        # Step B: 画像をStorageに保存
        # -------------------------------------------------
        # ファイル名に日時をつけて重複を防ぎます
        filename = f"cards/{profile.nickname}_{datetime.datetime.now().timestamp()}.png"
        blob = bucket.blob(filename)
        blob.upload_from_string(image_bytes, content_type='image/png')
        blob.make_public() 
        image_url = blob.public_url

        # -------------------------------------------------
        # Step C: Firestoreに保存 (★ここを変更しました)
        # -------------------------------------------------
        # コレクション名を 'p2hacks2025' に指定
        doc_ref = db.collection('p2hacks2025').add({
            'nickname': profile.nickname,
            'birthday': profile.birthday,
            'birthplace': profile.birthplace,
            'trivia': profile.trivia,
            'card_image_url': image_url,
            'created_at': datetime.datetime.now()
        })

        print(f"保存完了: ID={doc_ref[1].id}")

        return {
            "status": "success",
            "message": "p2hacks2025コレクションに保存しました",
            "data": {
                "nickname": profile.nickname,
                "image_url": image_url
            }
        }

    except Exception as e:
        print(f"エラー発生: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/")
def read_root():
    return {"message": "Kira-Kira Hackathon API is running!"}
  
  
@app.post("/submit-trivia")
def receive_trivia(profile: TriviaProfile):
    """
    フロントエンドからトリビア情報を受け取るAPI
    """
    print(f"受信したデータ: {profile.nickname}, {profile.trivia_text}")
    
    # TODO: ここにデータベースへの保存処理や、AI画像生成の処理を書きます
    
    # フロントへの返信（レスポンス）
    return {
        "status": "success",
        "message": f"{profile.nickname}さんのトリビアを受け取りました！",
        "received_data": {
            "trivia": profile.trivia_text,
            "generated_image_url": "https://example.com/dummy_ai_image.png" # ここに生成された画像のURLが入る想定
        }
    }