import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

/// A1: logo only while the session restores (never waits on the network).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Scaffold(
      backgroundColor: c.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/app_logo.png', width: 96, height: 96),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.appTitle, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
