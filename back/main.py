from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
import requests, base64

# =====================
# 設定
# =====================
SD_API_URL = "http://127.0.0.1:7860/sdapi/v1/txt2img"

app = FastAPI(
    title="Local SD Image Generation API",
    description="FastAPI + Stable Diffusion (local GPU)",
    version="1.0.0"
)

# =====================
# 入力モデル
# =====================
class GenerateRequest(BaseModel):
    prompt: str
    negative_prompt: str | None = "low quality, blurry"
    steps: int = 20
    width: int = 512
    height: int = 512
    cfg_scale: float = 7.0
    seed: int = -1

# =====================
# ヘルスチェック
# =====================
@app.get("/")
def health():
    return {"status": "ok", "message": "FastAPI is running"}

# =====================
# 画像生成（PNG返却）
# =====================
@app.post("/generate-image")
def generate_image(req: GenerateRequest):
    payload = {
        "prompt": req.prompt,
        "negative_prompt": req.negative_prompt,
        "steps": req.steps,
        "width": req.width,
        "height": req.height,
        "cfg_scale": req.cfg_scale,
        "seed": req.seed
    }

    try:
        r = requests.post(SD_API_URL, json=payload, timeout=180)
        r.raise_for_status()
    except requests.exceptions.RequestException as e:
        raise HTTPException(
            status_code=500,
            detail=f"Stable Diffusion API error: {e}"
        )

    try:
        image_base64 = r.json()["images"][0]
        image_bytes = base64.b64decode(image_base64)
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Failed to decode image from Stable Diffusion"
        )

    return Response(
        content=image_bytes,
        media_type="image/png"
    )
