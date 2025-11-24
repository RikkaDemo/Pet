// (模块 3/4) V6.0 (3.2.2): WebSocket 消息模型
// 职责: 提供强类型的 JSON 解析工厂

// (✅ 修复: 移除了未使用的 'package:flutter/foundation.dart')

/// V6.0 (3.2.2) 类型 1: 法官回答
class JudgeAnswer {
  final String answer; // "是" | "否" | "无关"
  final int score; // 0, 1, 2, 3

  JudgeAnswer({required this.answer, required this.score});

  factory JudgeAnswer.fromJson(Map<String, dynamic> json) {
    return JudgeAnswer(
      answer: json['answer'] as String? ?? '无关',
      score: json['score'] as int? ?? 0,
    );
  }
}

/// V6.0 (3.2.2) 类型 2: 玩家得分
class PlayerScore {
  final String name;
  final int score;
  final int rank;

  PlayerScore({required this.name, required this.score, required this.rank});

  factory PlayerScore.fromJson(Map<String, dynamic> json) {
    return PlayerScore(
      name: json['name'] as String? ?? '未知玩家',
      score: json['score'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
    );
  }
}

/// V6.0 (3.2.2) 类型 2: 积分更新 (消息体)
class ScoreUpdate {
  final List<PlayerScore> players;

  ScoreUpdate({required this.players});

  factory ScoreUpdate.fromJson(Map<String, dynamic> json) {
    final List<dynamic> playerList = json['players'] as List<dynamic>? ?? [];
    return ScoreUpdate(
      players: playerList
          .map((e) => PlayerScore.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// V6.0 (3.2.2) 类型 3: 信息汇总
class SummaryUpdate {
  final String content;

  SummaryUpdate({required this.content});

  factory SummaryUpdate.fromJson(Map<String, dynamic> json) {
    return SummaryUpdate(
      content: json['content'] as String? ?? '',
    );
  }
}

/// V6.0 (3.2.2) 类型 5: 游戏胜利
class GameSolved {
  // 此消息目前没有负载 (payload), 仅靠 'type' 触发
  GameSolved();

  factory GameSolved.fromJson(Map<String, dynamic> json) {
    return GameSolved();
  }
}
