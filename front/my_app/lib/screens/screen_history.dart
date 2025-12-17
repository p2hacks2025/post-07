import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';
import '../models/encounter.dart';

/// すれ違い履歴を表示する画面
class ScreenHistory extends StatefulWidget {
  const ScreenHistory({super.key});

  @override
  State<ScreenHistory> createState() => _ScreenHistoryState();
}

class _ScreenHistoryState extends State<ScreenHistory> {
  final ProfileService _profileService = ProfileService();
  List<Encounter> _encounters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEncounterHistory();
  }

  /// すれ違い履歴を読み込む
  Future<void> _loadEncounterHistory() async {
    try {
      final encounters = await _profileService.loadEncounterHistory();
      setState(() {
        _encounters = encounters.reversed.toList(); // 新しい順に表示
        _isLoading = false;
      });
    } catch (e) {
      print('履歴読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 日時をフォーマット
  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy年MM月dd日 HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('すれ違い履歴'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _encounters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'まだすれ違いはありません',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _encounters.length,
                  itemBuilder: (context, index) {
                    final encounter = _encounters[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade600,
                          child: Text(
                            encounter.profile.nickname.isNotEmpty
                                ? encounter.profile.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          encounter.profile.nickname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(encounter.encounterTime),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (encounter.profile.hometown.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '出身地: ${encounter.profile.hometown}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        onTap: () {
                          // 詳細画面への遷移（将来的に実装）
                          _showEncounterDetail(encounter);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  /// すれ違い詳細をダイアログで表示
  void _showEncounterDetail(Encounter encounter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(encounter.profile.nickname),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('すれ違った日時', _formatDateTime(encounter.encounterTime)),
              if (encounter.profile.birthday.isNotEmpty)
                _buildDetailRow('誕生日', encounter.profile.birthday),
              if (encounter.profile.hometown.isNotEmpty)
                _buildDetailRow('出身地', encounter.profile.hometown),
              if (encounter.profile.trivia.isNotEmpty)
                _buildDetailRow('トリビア', encounter.profile.trivia),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
