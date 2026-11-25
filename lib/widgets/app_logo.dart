import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88, this.showName = false});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF12352F),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: size * 0.54,
        color: const Color(0xFF48D597),
      ),
    );
    if (!showName) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 14),
        Text(
          'PocketTrack',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ],
    );
  }
}
