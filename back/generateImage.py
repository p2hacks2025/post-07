import requests, base64

url = "http://127.0.0.1:7860/sdapi/v1/txt2img"

payload = {
    "prompt": "life of human",
    "steps": 15,
    "width": 512,
    "height": 512
}

r = requests.post(url, json=payload)
r.raise_for_status()

img = r.json()["images"][0]

with open("test.png", "wb") as f:
    f.write(base64.b64decode(img))

print("✅ test.png generated")
