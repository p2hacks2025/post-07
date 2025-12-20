import 'dart:convert';
import 'package:http/http.dart' as http; // 追加
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/encounter.dart';
import '../models/trivia_card.dart';

/// プロフィールとすれ違い履歴を永続化、およびサーバー通信を行うサービスクラス
class ProfileService {
  static const String _keyMyProfile = 'my_profile';
  static const String _keyEncounterHistory = 'encounter_history';
  static const String _keyDisplayedCards = 'displayed_trivia_cards';

  // サーバーのベースURL
  final String _baseUrl = 'https://cylinderlike-dana-cryoscopic.ngrok-free.dev';

  // --- 追加: サーバーから最新のプロフィール（へぇ数含む）を取得 ---
  Future<Profile?> fetchMyProfileFromServer() async {
    try {
      // サーバーのエンドポイント（例: /get_profile）
      final url = Uri.parse('$_baseUrl/get_profile');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        // サーバーから返ってきたJSONをProfileオブジェクトに変換
        // Profile.fromJsonString または Profile.fromJson が定義されている必要があります
        return Profile.fromJsonString(response.body);
      } else {
        print('サーバーエラー: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('サーバー接続エラー: $e');
      return null;
    }
  }

  /// 自分のプロフィールを保存/更新（ローカル）
  Future<void> saveMyProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMyProfile, profile.toJsonString());
  }

  /// 自分のプロフィールを読み込み（ローカル）
  Future<Profile?> loadMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyMyProfile);
    
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    // クラス内の適切な場所（loadMyProfileの下など）に追加
Future<Profile?> fetchMyProfileFromServer() async {
  try {
    // あなたのngrok URL
    final url = Uri.parse('https://cylinderlike-dana-cryoscopic.ngrok-free.dev/get_profile');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      // ステップ1で作ったfromJsonStringを使って変換
      return Profile.fromJsonString(response.body);
    } else {
      print('サーバーエラー: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('接続エラー: $e');
    return null;
  }
}
    
    try {
      return Profile.fromJsonString(jsonString);
    } catch (e) {
      print('プロフィール読み込みエラー: $e');
      return null;
    }
  }

  /// 新しいプロフィールIDを生成
  String generateProfileId() {
    return const Uuid().v4();
  }

  // === 以下、すれ違い履歴・展示カード機能はそのまま保持 ===

  Future<void> saveEncounter(Encounter encounter) async {
    final prefs = await SharedPreferences.getInstance();
    List<Encounter> history = await loadEncounterHistory();
    history.add(encounter);
    List<String> jsonList = history.map((e) => e.toJsonString()).toList();
    await prefs.setStringList(_keyEncounterHistory, jsonList);
  }

  Future<List<Encounter>> loadEncounterHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyEncounterHistory);
    if (jsonList == null || jsonList.isEmpty) return [];
    try {
      return jsonList.map((jsonString) => Encounter.fromJsonString(jsonString)).toList();
    } catch (e) {
      print('履歴読み込みエラー: $e');
      return [];
    }
  }

  Future<void> clearEncounterHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEncounterHistory);
  }

  Future<void> clearMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMyProfile);
  }

  Future<void> saveDisplayedCard(TriviaCard card) async {
    final prefs = await SharedPreferences.getInstance();
    List<TriviaCard> cards = await loadDisplayedCards();
    cards.add(card);
    if (cards.length > 10) cards = cards.sublist(cards.length - 10);
    List<String> jsonList = cards.map((c) => c.toJsonString()).toList();
    await prefs.setStringList(_keyDisplayedCards, jsonList);
  }

  Future<List<TriviaCard>> loadDisplayedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyDisplayedCards);
    if (jsonList == null || jsonList.isEmpty) return [];
    try {
      return jsonList.map((jsonString) => TriviaCard.fromJsonString(jsonString)).toList();
    } catch (e) {
      print('展示カード読み込みエラー: $e');
      return [];
    }
  }

  Future<void> clearDisplayedCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDisplayedCards);
  }
}