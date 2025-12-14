import os
from dotenv import load_dotenv
import google.generativeai as genai

def main():
    load_dotenv()  # ← これが重要

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel("models/gemini-2.5-flash")
    response = model.generate_content("日本語で自己紹介してください")
    print(response.text)

if __name__ == "__main__":
    main()
