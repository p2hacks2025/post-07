from dotenv import load_dotenv
import os
import requests

load_dotenv()

SEARCH_API = os.getenv("SEARCH_API")
URL = "https://api.search.brave.com/res/v1/web/search"

def search_evidence(trivia):
    query = f"{trivia} 本当 事実"

    params = {
        "q": query,
        "count": 5,
        "lang": "ja"
    }

    headers = {
        "Accept": "application/json",
        "X-Subscription-Token": SEARCH_API
    }

    res = requests.get(URL, params=params, headers=headers)
    res.raise_for_status()
    data = res.json()

    return [
        r["description"]
        for r in data.get("web", {}).get("results", [])
        if r.get("description")
    ]


def judge_trivia(trivia, texts):
    positive = 0

    for t in texts:
        if "心臓が3つ" in t or "心臓は3つ" in t or "three hearts" in t:
            positive += 1

    if positive >= 2:
        return {
            "judgement": "正確",
        }
    elif positive == 1:
        return {
            "judgement": "一部正確",
        }
    else:
        return {
            "judgement": "不正確 / 判断不能",
        }


if __name__ == "__main__":
    trivia = "タコの心臓は3つある"

    texts = search_evidence(trivia)
    result = judge_trivia(trivia, texts)

    output = {
        "trivia": trivia,
        **result
    }

    print(output)
