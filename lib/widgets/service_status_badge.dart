import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class ServiceStatusBadge extends StatelessWidget {
  final String status;
  final bool isDueSoon;

  const ServiceStatusBadge({
    super.key,
    required this.status,
    this.isDueSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    String label = status;
    IconData icon;

    if (status == AppConstants.statusCompleted) {
      bg = AppColors.infoLight;
      fg = AppColors.info;
      border = AppColors.info.withValues(alpha: 0.3);
      icon = Icons.check_circle_outline_rounded;
    } else if (status == AppConstants.statusOverdue) {
      bg = AppColors.dangerLight;
      fg = AppColors.danger;
      border = AppColors.danger.withValues(alpha: 0.3);
      icon = Icons.error_outline_rounded;
    } else if (isDueSoon) {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
      border = AppColors.warning.withValues(alpha: 0.3);
      label = 'Due Soon (<30d)';
      icon = Icons.access_time_rounded;
    } else {
      bg = AppColors.successLight;
      fg = AppColors.success;
      border = AppColors.success.withValues(alpha: 0.3);
      icon = Icons.calendar_today_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

