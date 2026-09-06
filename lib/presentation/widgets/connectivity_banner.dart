import 'dart:async';

import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Shown while the device has no connection.
///
/// Firestore serves cached documents offline, so the list keeps working; this
/// explains why the data may be stale rather than blocking the screen.
class ConnectivityBanner extends StatefulWidget {
  /// Injectable so a test can drive the states without a platform channel.
  final Stream<List<ConnectivityResult>>? stream;

  const ConnectivityBanner({super.key, this.stream});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;

  @override
  void initState() {
    super.initState();

    final stream =
        widget.stream ?? Connectivity().onConnectivityChanged;

    _subscription = stream.listen(
      (results) => _update(results),
      // Never let a connectivity error take the screen down.
      onError: (_) {},
    );
  }

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);

    if (offline != _offline && mounted) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: AppDuration.fast,
      child: _offline
          ? Container(
              width: double.infinity,
              color: scheme.tertiaryContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 18,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'You are offline. Showing saved cars.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
