import 'package:flutter/material.dart';

import 'catalunya_card.dart';

class CatalunyaNavTile extends StatelessWidget {
  const CatalunyaNavTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CatalunyaCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: leading,
        title: Text(title),
        subtitle: (subtitle ?? '').isEmpty ? null : Text(subtitle!),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
