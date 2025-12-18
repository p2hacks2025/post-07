import 'dart:convert';
import 'profile.dart';

/// すれ違い履歴を管理するデータモデル
class Encounter {
  final Profile profile; // すれ違った相手のプロフィール
  final DateTime encounterTime; // すれ違った日時

  Encounter({
    required this.profile,
    required this.encounterTime,
  });

  /// JSONからEncounterオブジェクトを作成
  factory Encounter.fromJson(Map<String, dynamic> json) {
    return Encounter(
      profile: Profile.fromJson(json['profile']),
      encounterTime: DateTime.parse(json['encounterTime']),
    );
  }

  /// EncounterオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'encounterTime': encounterTime.toIso8601String(),
    };
  }

  /// EncounterオブジェクトをJSON文字列に変換
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// JSON文字列からEncounterオブジェクトを作成
  factory Encounter.fromJsonString(String jsonString) {
    return Encounter.fromJson(jsonDecode(jsonString));
  }
}
