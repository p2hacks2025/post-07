import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/encounter.dart';
import '../models/trivia_card.dart';

/// プロフィールとすれ違い履歴を永続化するサービスクラス
class ProfileService {
  static const String _keyMyProfile = 'my_profile';
  static const String _keyEncounterHistory = 'encounter_history';
  static const String _keyDisplayedCards = 'displayed_trivia_cards';

  /// 自分のプロフィールを保存/更新
  Future<void> saveMyProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMyProfile, profile.toJsonString());
  }

  /// 自分のプロフィールを読み込み
  Future<Profile?> loadMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyMyProfile);
    
    if (jsonString == null || jsonString.isEmpty) {
      return null;
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

  /// すれ違い履歴を追加保存
  Future<void> saveEncounter(Encounter encounter) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 既存の履歴を読み込み
    List<Encounter> history = await loadEncounterHistory();
    
    // 新しいすれ違いを追加
    history.add(encounter);
    
    // JSON文字列のリストに変換
    List<String> jsonList = history.map((e) => e.toJsonString()).toList();
    
    // 保存
    await prefs.setStringList(_keyEncounterHistory, jsonList);
  }

  /// すれ違い履歴の全リストを読み込み
  Future<List<Encounter>> loadEncounterHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyEncounterHistory);
    
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }
    
    try {
      return jsonList.map((jsonString) => Encounter.fromJsonString(jsonString)).toList();
    } catch (e) {
      print('履歴読み込みエラー: $e');
      return [];
    }
  }

  /// すれ違い履歴をクリア（デバッグ用）
  Future<void> clearEncounterHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEncounterHistory);
  }

  /// 自分のプロフィールをクリア（デバッグ用）
  Future<void> clearMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMyProfile);
  }

  // ===== トリビアカード展示機能 =====

  /// トリビアカードをホーム画面展示リストに追加
  Future<void> saveDisplayedCard(TriviaCard card) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 既存の展示カードを読み込み
    List<TriviaCard> cards = await loadDisplayedCards();
    
    // 新しいカードを追加（最大10枚まで）
    cards.add(card);
    if (cards.length > 10) {
      cards = cards.sublist(cards.length - 10); // 古いものから削除
    }
    
    // JSON文字列のリストに変換
    List<String> jsonList = cards.map((c) => c.toJsonString()).toList();
    
    // 保存
    await prefs.setStringList(_keyDisplayedCards, jsonList);
  }

  /// ホーム画面に展示するカードの全リストを読み込み
  Future<List<TriviaCard>> loadDisplayedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyDisplayedCards);
    
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }
    
    try {
      return jsonList.map((jsonString) => TriviaCard.fromJsonString(jsonString)).toList();
    } catch (e) {
      print('展示カード読み込みエラー: $e');
      return [];
    }
  }

  /// 展示カードをクリア（デバッグ用）
  Future<void> clearDisplayedCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDisplayedCards);
  }
}
