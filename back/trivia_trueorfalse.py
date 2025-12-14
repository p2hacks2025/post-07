import os
from dotenv import load_dotenv
import google.generativeai as genai

def trivia_trueorfalse(trivia: str):
    load_dotenv()

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel("models/gemini-2.5-flash")

    prompt = f"""
    あなたはファクトチェッカーです。
    以下の文が事実として正しいかどうかを判断してください。

    【ルール】
    ・出力は True または False のみ
    ・理由、説明、補足は禁止
    ・改行や空白も不要
    ・あなたの一般的・学術的知識に基づいて判断すること

    【検証対象】
    {trivia}
    """

    response = model.generate_content(prompt)
    text = response.text.strip()

    print("LLM出力:", text)

    if text == "True":
        print("正しい!")
        return True
    if text == "False":
        print("違った!")
        return False

    print("判断不能")
    return None


if __name__ == "__main__":
    trivia_trueorfalse("ハワイは日本に少しずつ近づいている")
