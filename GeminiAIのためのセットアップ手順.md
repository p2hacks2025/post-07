1. リポジトリクローン(or プル)

2. 仮想環境の作成・有効化
    * Anaconda を インストール
    * anaconda プロンプト を起動
    * conda create -n gemini-env python=3.10.19
    * conda activate gemini-env

3. ライブラリのインストール
    * pip install google-generativeai
    * pip install python-dotenv

4. APIキーの設定
    * .env内の GEMINI_API_KEY="通知したものに変更"

5. 実行
    * python back/test/geminitest.py