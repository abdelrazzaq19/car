import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xff17161C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/onboarding.png', fit: BoxFit.cover),
          // Scrim, so the copy stays legible whatever the photo does behind it.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.25, 0.6, 1],
                colors: [
                  Colors.transparent,
                  Color(0xCC17161C),
                  Color(0xFF17161C),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium cars,\nenjoy the luxury',
                    style: theme.textTheme.displaySmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  Text(
                    'Premium and prestige cars for daily rental. '
                    'Experience the thrill at a lower price.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff17161C),
                      ),
                      onPressed: () => context.push(Routes.cars),
                      child: const Text("Let's go"),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
