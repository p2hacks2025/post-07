import 'dart:convert';

class Profile {
  final String profileId;
  final String nickname;
  final String birthday;
  final String birthplace;
  final String trivia;
  final int totalHeh; // ★ここが重要：合計へぇ数

  Profile({
    required this.profileId,
    required this.nickname,
    required this.birthday,
    required this.birthplace,
    required this.trivia,
    this.totalHeh = 0, // デフォルトは0
  });

  // JSON文字列からProfileオブジェクトを作る
  factory Profile.fromJsonString(String str) => Profile.fromJson(json.decode(str));

  // ProfileオブジェクトをJSON文字列にする
  String toJsonString() => json.encode(toJson());

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    profileId: json["profileId"] ?? "",
    nickname: json["nickname"] ?? "",
    birthday: json["birthday"] ?? "",
    birthplace: json["birthplace"] ?? "",
    trivia: json["trivia"] ?? "",
    totalHeh: json["total_heh"] ?? 0, // サーバー側のキー名（total_heh）に合わせる
  );

  Map<String, dynamic> toJson() => {
    "profileId": profileId,
    "nickname": nickname,
    "birthday": birthday,
    "birthplace": birthplace,
    "trivia": trivia,
    "total_heh": totalHeh,
  };
}