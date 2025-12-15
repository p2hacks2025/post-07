import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

class ScreenEncounter extends StatefulWidget {
  final String detectedUserId;
  
  const ScreenEncounter({
    super.key,
    required this.detectedUserId,
  });

  @override
  State<ScreenEncounter> createState() => _ScreenEncounterState();
}

class _ScreenEncounterState extends State<ScreenEncounter> {
  String? _favoriteFood;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteFood();
  }

  // サーバーから好きな食べ物の情報を取得
  Future<void> _fetchFavoriteFood() async {
    try {
      // 実際のサーバーがないため、Future.delayedでダミーレスポンスをシミュレーション
      await Future.delayed(const Duration(seconds: 2));
      
      // ダミーのJSONレスポンスをシミュレーション
      // 実際のコード例:
      // final response = await http.get(
      //   Uri.parse('https://api.example.com/food?id=${widget.detectedUserId}'),
      // );
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   setState(() {
      //     _favoriteFood = data['food'];
      //     _isLoading = false;
      //   });
      // }
      
      // ダミーデータ（デバイスIDに応じて異なる食べ物を返す）
      final dummyFoods = ['寿司', 'カレー', 'ラーメン', 'ピザ', 'パスタ', 'うどん'];
      final foodIndex = widget.detectedUserId.hashCode % dummyFoods.length;
      final dummyResponse = {'food': dummyFoods[foodIndex.abs()]};
      
      if (mounted) {
        setState(() {
          _favoriteFood = dummyResponse['food'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('すれ違い検知'),
        backgroundColor: Colors.purple.shade400,
      ),
      body: Center(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // ロード中
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.purple,
          ),
          SizedBox(height: 20),
          Text(
            '情報を取得中...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    // エラー
    if (_hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          const Text(
            '情報の取得に失敗しました',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _fetchFavoriteFood();
            },
            child: const Text('再試行'),
          ),
        ],
      );
    }

    // 成功
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'すれ違いを検知しました！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '検知した相手の仮ID:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.detectedUserId,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.purple.shade200, width: 2),
          ),
          child: Column(
            children: [
              const Text(
                '好きな食べ物',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.purple,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _favoriteFood ?? '不明',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
