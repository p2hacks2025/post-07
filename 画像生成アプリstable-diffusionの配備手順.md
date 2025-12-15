# Stable Diffusion ローカル配備手順書

## 1. 前提条件

* OS: Windows 10/11
* Python 3.10〜3.11
* GPU (CUDA 対応) 推奨
* Git インストール済み
* GitHub アカウント

---

## 2. GitHub リポジトリのクローン

```powershell
# 任意の作業フォルダへ移動
cd E:\p2hacks2025\back

# WebUIリポジトリをクローン
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git

cd stable-diffusion-webui
```

※ `.gitignore` によりモデルや venv は含まれません。

---

## 3. モデルのダウンロード

### 推奨モデル：v1-5


1. google検索で`runwayml / stable-diffusion-v1-5` にアクセス、Hugging Faceに飛ぶ
2. ファイル `v1-5-pruned-emaonly.safetensors` をダウンロード
3. フォルダに配置

```
stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned-emaonly.safetensors
```

---

## 4. Python 仮想環境の準備

### Windows + PowerShell

```powershell
# WebUI フォルダ内で
.\webui-user.bat
```

* 初回は仮想環境作成 & 依存関係インストールが自動で走ります
* 途中で「新しい環境を作成しますか？」 → **Yes**

---

## 5. APIモードで起動

```powershell
# WebUI フォルダ内
.\webui-user.bat --api --nowebui
```

* 起動完了ログに以下が出れば成功

```
Running on local URL:  http://127.0.0.1:7860
```

---

## 6. API動作確認

### サンプラー確認

```powershell
curl http://127.0.0.1:7860/sdapi/v1/samplers
```

* JSONでサンプラー一覧が返れば OK

### 画像生成テスト（Python）

```python
import requests, base64

url = "http://127.0.0.1:7860/sdapi/v1/txt2img"

payload = {
    "prompt": "simple pastel illustration of an octopus",
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
```

---

## 7. 注意点

* **models/ フォルダとモデルファイルは GitHub で管理しない**
* GPU不足の場合は `--medvram` を付けて起動
* APIを使う場合は常に WebUI フォルダ内で `.bat` 実行

---

## 8. オプション

* **再現性確保**: `seed` パラメータを指定
* **生成サイズ変更**: `width` / `height` を調整
* **Geminiや他サービスと連動**: Pythonスクリプトから `txt2img` API を呼ぶ

---

💡 この手順で、GitHub から受け取った人も **環境構築 → モデル配置 → API起動 → 画像生成** まで完結できます。
