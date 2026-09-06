import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Shared empty / error state. Scrollable so it still works as the child of a
/// `RefreshIndicator` and does not overflow at large text scales.
class StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  /// Defaults to "Try again"; set when the action is not a retry, e.g.
  /// "Clear filters".
  final String? actionLabel;

  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: Icon(
                        actionLabel == null ? Icons.refresh : Icons.filter_alt_off,
                      ),
                      label: Text(actionLabel ?? 'Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
