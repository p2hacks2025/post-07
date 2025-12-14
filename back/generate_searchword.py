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
    response = model.generate_content(text + "\nこの文についてインターネットで調べる際、真偽に必要な主要キーワードを集めてください。"
                                      + "\nプログラムに流すので助詞の違いや少しの違いがあってもすべて記載してください"
                                      + "\nまた、類似検索などはしないのでそのまま使える単語のみを提示してください"
                                      + "\n返答は 単語,単語,単語,...のようにしてください")
    print(response.text)

if __name__ == "__main__":
    main()
