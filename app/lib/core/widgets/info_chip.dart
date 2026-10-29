import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InfoChip extends StatelessWidget {
  const InfoChip(this.label,
      {super.key,
      this.bg = AppColors.surfaceMuted,
      this.fg = AppColors.textChip});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
