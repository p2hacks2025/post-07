from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
import os
import base64
import requests

# =====================
# SD API URL
# =====================
TXT2IMG_API_URL = "http://127.0.0.1:7860/sdapi/v1/txt2img"
IMG2IMG_API_URL = "http://127.0.0.1:7860/sdapi/v1/img2img"

app = FastAPI(title="Trivia → Image API")

# =====================
# リクエストモデル
# =====================
class GenerateRequest(BaseModel):
    trivia: str
    steps: int = 35
    width: int = 512
    height: int = 512

class Img2ImgRequest(BaseModel):
    prompt: str                 # 直接ユーザー指定プロンプト
    input_image_path: str       # サーバーにある画像パス
    steps: int = 35
    width: int = 512
    height: int = 512
    denoising_strength: float = 0.55

# =====================
# ヘルスチェック
# =====================
@app.get("/")
def health():
    return {"status": "ok"}

@app.get("/health")
def health_check():
    return {"status": "ok"}

# =====================
# txt2img
# =====================
@app.post("/generate-image")
def generate_image(req: GenerateRequest):
    payload = {
        "prompt": req.trivia,
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
        r = requests.post(TXT2IMG_API_URL, json=payload, timeout=180)
        r.raise_for_status()
        img_base64 = r.json()["images"][0]
        img_bytes = base64.b64decode(img_base64)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image generation failed: {e}")

    return Response(content=img_bytes, media_type="image/png")

# =====================
# img2img
# =====================
@app.post("/generate-img2img")
def generate_img2img(req: Img2ImgRequest):
    if not os.path.exists(req.input_image_path):
        raise HTTPException(status_code=400, detail="Input image not found")

    # 入力画像をbase64化
    with open(req.input_image_path, "rb") as f:
        init_img = base64.b64encode(f.read()).decode("utf-8")

    payload = {
        "init_images": [init_img],
        "prompt": req.prompt,
        "negative_prompt": (
            "low quality, worst quality, blurry, grainy, pixelated, jpeg artifacts, "
            "bad anatomy, extra limbs, missing limbs, wrong hands, malformed face, "
            "text, logo, watermark, signature, username, nsfw, nudity, gore, violence"
        ),
        "denoising_strength": req.denoising_strength,
        "steps": req.steps,
        "width": req.width,
        "height": req.height
    }

    try:
        r = requests.post(IMG2IMG_API_URL, json=payload, timeout=180)
        r.raise_for_status()
        img_base64 = r.json()["images"][0]
        img_bytes = base64.b64decode(img_base64)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Img2Img generation failed: {e}")

    return Response(content=img_bytes, media_type="image/png")
