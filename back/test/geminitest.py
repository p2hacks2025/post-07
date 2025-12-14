import os
import google.generativeai as genai

def main():
    # 環境変数から APIキーを読む
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY が設定されていません")

    genai.configure(api_key=api_key)

    # 無料枠で確実に使えるモデル
    model = genai.GenerativeModel("models/gemini-2.5-flash")

    response = model.generate_content(
        "日本語で20文字以内の自己紹介をしてください"
    )

    print("=== Gemini response ===")
    print(response.text)

if __name__ == "__main__":
    main()
