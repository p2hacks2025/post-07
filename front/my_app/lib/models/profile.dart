import 'dart:convert';

/// プロフィール情報を管理するデータモデル
class Profile {
  final String profileId; // 一意なID
  final String nickname;
  final String birthday; // 誕生日（例: "2000-01-01"）
  final String hometown; // 出身地
  final String trivia; // トリビア・自己紹介

  Profile({
    required this.profileId,
    required this.nickname,
    required this.birthday,
    required this.hometown,
    required this.trivia,
  });

  /// JSONからProfileオブジェクトを作成
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      profileId: json['profileId'] ?? '',
      nickname: json['nickname'] ?? '',
      birthday: json['birthday'] ?? '',
      hometown: json['hometown'] ?? '',
      trivia: json['trivia'] ?? '',
    );
  }

  /// ProfileオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'nickname': nickname,
      'birthday': birthday,
      'hometown': hometown,
      'trivia': trivia,
    };
  }

  /// ProfileオブジェクトをJSON文字列に変換
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// JSON文字列からProfileオブジェクトを作成
  factory Profile.fromJsonString(String jsonString) {
    return Profile.fromJson(jsonDecode(jsonString));
  }
}
