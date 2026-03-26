import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class DisclaimerBanner extends StatelessWidget {
  final bool compact;

  const DisclaimerBanner({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Text(
        compact ? AppConstants.disclaimerShort : AppConstants.disclaimerFull,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: compact ? 11 : 12,
          height: 1.5,
        ),
      ),
    );
  }
}
