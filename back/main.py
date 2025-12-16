from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
import os
import base64
import requests
from dotenv import load_dotenv
import google.generativeai as genai

# =====================
# 初期化
# =====================
load_dotenv(override=True)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY is not set")

genai.configure(api_key=GEMINI_API_KEY)

SD_API_URL = "http://127.0.0.1:7860/sdapi/v1/txt2img"

app = FastAPI(
    title="Trivia → Image API",
    description="Gemini + Stable Diffusion via FastAPI",
    version="1.0.0"
)

# =====================
# リクエストモデル
# =====================
class GenerateRequest(BaseModel):
    trivia: str
    steps: int = 35
    width: int = 512
    height: int = 512

# =====================
# ヘルスチェック
# =====================
@app.get("/")
def health():
    return {"status": "ok"}

# =====================
# メインAPI
# =====================
@app.post("/generate-image")
def generate_image(req: GenerateRequest):
    # ---- Geminiでプロンプト生成 ----
    model = genai.GenerativeModel("models/gemini-2.5-flash")

    response = model.generate_content(
        req.trivia + "\n以下のルールに従ってください：\n"
        "・出力は1行のテキストのみ\n"
        "・余計な文章や返事は一切不要\n"
        "・コンマ区切りの英単語でAIにコピペ可能な形\n"
        "・必ず以下の単語を含める：Hand-drawn, Deformed, Pastel colors"
    )

    prompt = response.text.strip()

    # ---- Stable Diffusion ----
    payload = {
        "prompt": prompt,
        "negative_prompt": (
            "low quality, worst quality, blurry, grainy, pixelated, jpeg artifacts,"
            " bad anatomy, deformed, extra limbs, missing limbs, wrong hands,"
            " malformed face, text, logo, watermark, signature, username,"
            " nsfw, nudity, gore, violence, overexposed, oversaturated, ugly"
        ),
        "steps": req.steps,
        "width": req.width,
        "height": req.height
    }

    try:
        r = requests.post(SD_API_URL, json=payload, timeout=180)
        r.raise_for_status()
        img_base64 = r.json()["images"][0]
        img_bytes = base64.b64decode(img_base64)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Image generation failed: {e}"
        )

    # ---- PNG をそのまま返す ----
    return Response(
        content=img_bytes,
        media_type="image/png"
    )
