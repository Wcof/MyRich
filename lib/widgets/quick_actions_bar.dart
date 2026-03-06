import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback? onAddAsset;
  final VoidCallback? onViewDetails;
  final VoidCallback? onRefresh;

  const QuickActionsBar({
    super.key,
    this.onAddAsset,
    this.onViewDetails,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_rounded,
              label: '添加资产',
              color: const Color(0xFF1E293B),
              onTap: onAddAsset,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: _buildActionButton(
              icon: Icons.list_alt_rounded,
              label: '查看详情',
              color: const Color(0xFF6366F1),
              onTap: onViewDetails,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildActionButton(
                icon: Icons.refresh_rounded,
                label: '刷新',
                color: const Color(0xFF8B5CF6),
                onTap: onRefresh,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
