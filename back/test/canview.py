import json
import base64

# JSONファイルを読む
with open("response_1765897246805.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# base64を取り出す
image_base64 = data["image_base64"]

# デコード
image_bytes = base64.b64decode(image_base64)

# 保存
with open("result.png", "wb") as f:
    f.write(image_bytes)

print("result.png saved")
