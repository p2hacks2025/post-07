1. リポジトリクローン(or プル)

2. 仮想環境の作成・有効化
    * Anaconda を インストール
    * anaconda プロンプト を起動
    * conda create -n gemini-env python=3.10.19
    * conda activate gemini-env

3. ライブラリのインストール
    * pip install google-generativeai
    * pip install python-dotenv

4. vscodeの再起動

5. python インタプリの指定
    * ctrl + shift + p
    * python select インタプリタ的なの
    * 'gemini-env' がついてるものを選択

6. APIキーの設定
    * .env内の GEMINI_API_KEY="通知したものに変更"

7. 呪文
    * conda activate gemini-env
    ↑vscode内のターミナルで起動

8. 仮想環境の設定
    * conda activate gemini-env
    
9. 実行
    * python back/test/geminitest.py