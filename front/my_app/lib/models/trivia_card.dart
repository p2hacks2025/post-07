import 'dart:convert';

/// トリビアカードのデータモデル
class TriviaCard {
  final String id; // カードの一意なID
  final String title; // カードのタイトル
  final String content; // トリビアの内容
  final int heeCount; // 「へー」の数
  final DateTime completedAt; // 完了した日時

  TriviaCard({
    required this.id,
    required this.title,
    required this.content,
    required this.heeCount,
    required this.completedAt,
  });

  /// JSONからTriviaCardオブジェクトを作成
  factory TriviaCard.fromJson(Map<String, dynamic> json) {
    return TriviaCard(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      heeCount: json['heeCount'] ?? 0,
      completedAt: DateTime.parse(json['completedAt']),
    );
  }

  /// TriviaCardオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'heeCount': heeCount,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  /// TriviaCardオブジェクトをJSON文字列に変換
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// JSON文字列からTriviaCardオブジェクトを作成
  factory TriviaCard.fromJsonString(String jsonString) {
    return TriviaCard.fromJson(jsonDecode(jsonString));
  }
}
