import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/analysis_provider.dart';
import '../models/analysis_result.dart';
import '../widgets/disclaimer_banner.dart';

class ResultScreen extends StatefulWidget {
  final String analysisId;

  const ResultScreen({super.key, required this.analysisId});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().getResult(widget.analysisId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, analysis, _) {
          final result = analysis.result;
          if (result == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 면책 배너
                const DisclaimerBanner(compact: true),
                const SizedBox(height: 24),

                // 종합 점수
                _ScoreCard(
                  score: result.score ?? 0,
                  grade: result.grade ?? '확인 필요',
                ),
                const SizedBox(height: 24),

                // 체크 항목
                if (result.checkItems.isNotEmpty) ...[
                  const Text(
                    '체크 포인트',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.checkItems.map((item) => _CheckItemCard(item: item)),
                  const SizedBox(height: 24),
                ],

                // 쉬운 말 해설
                if (result.summary != null) ...[
                  const Text(
                    '쉬운 말 해설',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      result.summary!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 참고 대화 예시
                if (result.talkExamples.isNotEmpty) ...[
                  const Text(
                    '참고 대화 예시',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.talkExamples.map((example) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(30),
                          ),
                        ),
                        child: Text(
                          '"$example"',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )),
                  const SizedBox(height: 24),
                ],

                // 추천 특약
                if (result.recommendedClauses.isNotEmpty) ...[
                  const Text(
                    '추천 특약 문구',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.recommendedClauses.map((clause) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withAlpha(30),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                clause,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                ],

                // 전체 면책
                const DisclaimerBanner(compact: false),
                const SizedBox(height: 32),

                // 홈으로
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '홈으로 돌아가기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String grade;

  const _ScoreCard({required this.score, required this.grade});

  Color get _gradeColor => switch (grade) {
        '양호' => AppColors.success,
        '주의 권장' => AppColors.warning,
        '확인 필요' => AppColors.caution,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gradeColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: _gradeColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '/ 100점',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _gradeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _gradeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItemCard extends StatelessWidget {
  final CheckItem item;

  const _CheckItemCard({required this.item});

  Color get _statusColor => switch (item.status) {
        '양호' => AppColors.success,
        '주의 권장' => AppColors.warning,
        '확인 필요' => AppColors.caution,
        _ => AppColors.primary,
      };

  IconData get _statusIcon => switch (item.status) {
        '양호' => Icons.check_circle_outline,
        '주의 권장' => Icons.warning_amber_outlined,
        '확인 필요' => Icons.error_outline,
        _ => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon, size: 20, color: _statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
