import requests, base64

def generate_img2img(
    prompt,
    input_image_path="test.png"
    # 本当はface.pngみたいなの
):
    url = "https://17413e299b41.ngrok-free.app/sdapi/v1/img2img"

    # 入力画像をbase64化
    with open(input_image_path, "rb") as f:
        init_img = base64.b64encode(f.read()).decode("utf-8")

    payload = {
        "init_images": [init_img],
        "prompt": prompt,
        "negative_prompt": (
            "low quality, worst quality, blurry, grainy, pixelated, jpeg artifacts, "
            "bad anatomy, extra limbs, missing limbs, wrong hands, malformed face, "
            "text, logo, watermark, signature, username, nsfw, nudity, gore, violence"
        ),
        "denoising_strength": 0.55,
        "steps": 35,
        "width": 512,
        "height": 512
    }

    r = requests.post(
        url,
        json=payload,
        auth=("user", "password")
    )
    r.raise_for_status()

    img = r.json()["images"][0]

    with open("img2img.png", "wb") as f:
        f.write(base64.b64decode(img))

    print("img2img.png generated")


if __name__ == "__main__":
    generate_img2img(
        prompt="Hand-drawn, Deformed, Pastel colors, whimsical illustration"
    )
