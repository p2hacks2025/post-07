from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from datetime import date

app = FastAPI()

# --- 1. CORS設定 (フロントエンドからのアクセスを許可) ---
# これがないとブラウザからAPIを叩いた時にエラーになります
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 本番では特定のURLに絞りますが、ハッカソン中は"*"で全許可が楽です
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 2. データモデルの定義 (Pydantic) ---
# フロントエンドから送られてくるデータの「型」を定義します
class TriviaProfile(BaseModel):
    nickname: str
    birthday: str  # "2000-01-01" などの文字列として受け取る想定
    hometown: str
    trivia_text: str
    # 写真データは通常Base64文字列かファイルアップロードになりますが、
    # ここでは簡易的に文字列として定義しておきます
    photo_data: str | None = None 

# --- 3. APIエンドポイントの実装 ---

@app.get("/")
def read_root():
    return {"message": "Kira-Kira Hackathon API is running!"}

# フロントからデータを「受け取る」ためのPOSTメソッド
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