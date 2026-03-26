class AnalysisResult {
  final String id;
  final String userId;
  final int? score;
  final String? grade; // '양호', '주의 권장', '확인 필요'
  final Map<String, dynamic>? resultJson;
  final List<String> documentsUploaded;
  final DateTime createdAt;

  AnalysisResult({
    required this.id,
    required this.userId,
    this.score,
    this.grade,
    this.resultJson,
    this.documentsUploaded = const [],
    required this.createdAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'],
      userId: json['user_id'],
      score: json['score'],
      grade: json['grade'],
      resultJson: json['result_json'],
      documentsUploaded:
          List<String>.from(json['documents_uploaded'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // 결과 JSON에서 항목별 데이터 추출
  List<CheckItem> get checkItems {
    final items = resultJson?['items'] as List<dynamic>?;
    if (items == null) return [];
    return items.map((e) => CheckItem.fromJson(e)).toList();
  }

  String? get summary => resultJson?['summary'];
  List<String> get talkExamples =>
      List<String>.from(resultJson?['talk_examples'] ?? []);
  List<String> get recommendedClauses =>
      List<String>.from(resultJson?['recommended_clauses'] ?? []);
}

class CheckItem {
  final String category;
  final String status; // '양호', '주의 권장', '확인 필요', '참고'
  final String title;
  final String description;
  final String? recommendation;

  CheckItem({
    required this.category,
    required this.status,
    required this.title,
    required this.description,
    this.recommendation,
  });

  factory CheckItem.fromJson(Map<String, dynamic> json) {
    return CheckItem(
      category: json['category'] ?? '',
      status: json['status'] ?? '참고',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      recommendation: json['recommendation'],
    );
  }
}
