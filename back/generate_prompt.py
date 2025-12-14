import os
from dotenv import load_dotenv
import google.generativeai as genai

def main():
    load_dotenv()

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel("models/gemini-2.5-flash")
    text="タコの心臓は3つある"
    response = model.generate_content(text + "\nこの文を画像生成AIのプロンプト用に1文のコンマ区切りにするように書き換えてください。"
                                      + "\nそのままコピペでAIに入力できるような形でお願いします。"
                                      + "\nまた、以下の単語も含めてください 。{Hand-drawn},{Deformed},{Pastel colors}")
    print(response.text)

if __name__ == "__main__":
    main()
