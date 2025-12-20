from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, Response
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import datetime
import os
import base64
import requests
from dotenv import load_dotenv
import google.generativeai as genai
from typing import Dict


# Firebase
import databaseConnect

# =====================
# FastAPI 初期化
# =====================
app = FastAPI(title="Profile + Trivia + Card API")

databaseConnect.initialize()
db = databaseConnect.get_db()
bucket = databaseConnect.get_bucket()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================
# Stable Diffusion API（同一 ngrok）
# =====================
SD_API_URL = "http://127.0.0.1:7860/sdapi/v1/txt2img"
SD_AUTH = ("user", "password")  # 必要な場合のみ

# =====================
# リクエストモデル
# =====================
class saveUserProfile(BaseModel):
    nickname: str
    birthday: str
    birthplace: str
    trivia: str
    id: str
    ver: int
    hey: int

class getUserProfile(BaseModel):
    id: str
    ver: int

class getotherUserProfiles(BaseModel):
    targets: Dict[str, int]  # { id: ver }

class heycount(BaseModel):
    id: str
    ver: int
    pushedhey:int

# =====================
# Gemini：トリビア真偽判定
# =====================
def trivia_trueorfalse(trivia: str) -> bool | None:
    load_dotenv(override=True)
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("models/gemini-2.5-flash")

    prompt = f"""
            あなたはファクトチェッカーです。
            以下の文が事実として正しいかどうかを判断してください。

            【ルール】
            ・出力は True または False のみ
            ・理由、説明、補足は禁止

            【検証対象】
            {trivia}
            """

    text = model.generate_content(prompt).text.strip()
    if text == "True":
        return True
    if text == "False":
        return False
    return None

# =====================
# 画像生成（Gemini → SD）
# =====================
def generate_image(trivia: str, steps: int, width: int, height: int) -> bytes:
    load_dotenv(override=True)

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("models/gemini-2.5-flash")

    # ① Geminiでプロンプト生成
    prompt_response = model.generate_content(
        trivia +
        "\n以下のルールに従ってください：\n"
        "・出力は1行のみ\n"
        "・英単語のみ、カンマ区切り\n"
        "・必ず含める：Hand-drawn, Deformed, Pastel colors"
    )

    prompt_text = prompt_response.text.strip()

    # ② Stable Diffusion
    payload = {
        "prompt": prompt_text,
        "negative_prompt": (
            "low quality, worst quality, blurry, grainy, pixelated, "
            "jpeg artifacts, bad anatomy, extra limbs, missing limbs, "
            "wrong hands, malformed face, text, logo, watermark, "
            "signature, username, nsfw, nudity, gore, violence"
        ),
        "steps": steps,
        "width": width,
        "height": height
    }

    r = requests.post(
        SD_API_URL,
        json=payload,
        auth=SD_AUTH,
        timeout=180
    )
    r.raise_for_status()

    img_base64 = r.json()["images"][0]
    return base64.b64decode(img_base64)


# =====================
# Firebase Storage
# =====================
def upload_image_to_storage(image_bytes: bytes, filename: str) -> str:
    blob = bucket.blob(filename)
    blob.upload_from_string(image_bytes, content_type="image/png")
    blob.make_public()
    return blob.public_url

# =====================
# /save_profile
# =====================
@app.post("/save_profile")
def save_profile(profile: saveUserProfile):
    try:
        is_true = trivia_trueorfalse(profile.trivia)

        image_bytes = generate_image(
            trivia=profile.trivia,
            steps=35,
            width=512,
            height=512
        )

        timestamp = int(datetime.datetime.now().timestamp())
        # filename = f"cards/{profile.nickname}_{timestamp}.png"
        filename = f"cards/{profile.id}_v{profile.ver}.png"

        image_url = upload_image_to_storage(image_bytes, filename)

        db.collection("p2hacks2025").add({
            "nickname": profile.nickname,
            "birthday": profile.birthday,
            "birthplace": profile.birthplace,
            "trivia": profile.trivia,
            "is_true": is_true,
            "image_url": image_url,
            "ver": profile.ver,
            "id": profile.id,
            "created_at": datetime.datetime.now()
        })

        return JSONResponse({
            "status": "success",
            "image_url": image_url,
            "is_true": is_true,
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
# =====================
# /get_user_profile
# =====================
@app.post("/get_user_profile")
def get_user_profile(profile: getUserProfile):
    try:
        # Firestore クエリ
        query = (
            db.collection("p2hacks2025")
            .where("id", "==", profile.id)
            .where("ver", "==", profile.ver)
            .limit(1)
            .stream()
        )

        docs = list(query)

        if not docs:
            raise HTTPException(
                status_code=404,
                detail="Profile not found"
            )

        data = docs[0].to_dict()

        return JSONResponse({
            "status": "success",
            "data": {
                "nickname": data.get("nickname"),
                "birthday": data.get("birthday"),
                "birthplace": data.get("birthplace"),
                "trivia": data.get("trivia"),
                "is_true": data.get("is_true"),
                "image_url": data.get("image_url"),
                "id": data.get("id"),
                "ver": data.get("ver"),
            }
        })

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/get_otheruser_profiles")
def get_user_profiles(req: getotherUserProfiles):
    try:
        results = []

        for user_id, ver in req.targets.items():
            docs = (
                db.collection("p2hacks2025")
                .where("id", "==", user_id)
                .where("ver", "==", ver)
                .stream()
            )

            for doc in docs:
                data = doc.to_dict()
                data["doc_id"] = doc.id
                results.append(data)

        # datetime → JSON 変換
        return JSONResponse(
            status_code=200,
            content=jsonable_encoder(results)
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
from google.cloud.firestore import Increment

@app.post("/heyplus")
def hey_plus(req: heycount):
    try:
        # 対象ドキュメント取得
        docs = (
            db.collection("p2hacks2025")
            .where("id", "==", req.id)
            .where("ver", "==", req.ver)
            .limit(1)
            .stream()
        )

        docs = list(docs)

        if not docs:
            raise HTTPException(
                status_code=404,
                detail="Profile not found"
            )

        doc = docs[0]
        doc_ref = doc.reference
        data = doc.to_dict()

        # 現在の hey（なければ 0）
        current_hey = data.get("hey", 0)

        # 加算
        new_hey = current_hey + req.pushedhey

        # Firestore 更新
        doc_ref.update({
            "hey": new_hey,
            "updated_at": datetime.datetime.now()
        })

        return JSONResponse(
            status_code=200,
            content={
                "status": "success",
                "id": req.id,
                "ver": req.ver,
                "hey": new_hey
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =====================
# ヘルスチェック
# =====================
@app.get("/")
def root():
    return {"message": "Profile + Trivia + Card API running"}
