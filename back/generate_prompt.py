import os
from dotenv import load_dotenv
import google.generativeai as genai
import requests, base64

def henerateImagefromtrivia(trivia):
    load_dotenv(override=True)

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")
    
    url = "https://saliently-multiciliated-jacqui.ngrok-free.dev/sdapi/v1/txt2img"

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel("models/gemini-2.5-flash")
    response = model.generate_content(
    trivia + "\n以下のルールに従ってください：\n"
    "・出力は1行のテキストのみ\n"
    "・余計な文章や返事は一切不要\n"
    "・コンマ区切りの英単語でAIにコピペ可能な形\n"
    "・必ず以下の単語を含める：Hand-drawn, Deformed, Pastel colors"
)

    print(response.text)


    

    payload = {
        "prompt": response.text,
        "negative_prompt":"low quality, worst quality, blurry, grainy, pixelated, jpeg artifacts, bad anatomy, deformed,"
                                " extra limbs, missing limbs, wrong hands, malformed face,text, logo, watermark, signature, username,nsfw, nudity,"
                                " gore, violence,overexposed, oversaturated, ugly",
        "steps": 35,
        "width": 512,
        "height": 512
    }

    r = requests.post(url, json=payload,auth=("user", "password"))
    r.raise_for_status()

    img = r.json()["images"][0]

    with open("test.png", "wb") as f:
        f.write(base64.b64decode(img))

    print("test.png generated")


if __name__ == "__main__":
    henerateImagefromtrivia("付箋の由来は拷問器具")
