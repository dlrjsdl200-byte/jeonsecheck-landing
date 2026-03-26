import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/analysis_provider.dart';

class AnalyzingScreen extends StatelessWidget {
  final Map<String, dynamic>? uploadedFiles;

  const AnalyzingScreen({super.key, this.uploadedFiles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로딩 애니메이션
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withAlpha(30),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'AI가 서류를 분석하고 있어요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 현재 단계 표시
              Consumer<AnalysisProvider>(
                builder: (context, analysis, _) => Text(
                  analysis.currentStep.isEmpty
                      ? '잠시만 기다려주세요...'
                      : analysis.currentStep,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 진행 단계
              const _StepIndicator(
                steps: [
                  '서류 업로드',
                  'AI 분석',
                  '교차 검증',
                  '리포트 생성',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> steps;

  const _StepIndicator({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, analysis, _) {
        final currentStep = analysis.currentStep;
        int activeIndex = 0;
        if (currentStep.contains('분석')) activeIndex = 1;
        if (currentStep.contains('검증') || currentStep.contains('저장')) {
          activeIndex = 2;
        }
        if (currentStep.contains('리포트') || currentStep.contains('삭제')) {
          activeIndex = 3;
        }

        return Column(
          children: List.generate(steps.length, (i) {
            final isActive = i <= activeIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
