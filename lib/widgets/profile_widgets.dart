import 'package:flutter/material.dart';
import '../core/theme/app_pallete.dart';

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppPallete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppPallete.gradient1),
        title: Text(
          title,
          style: const TextStyle(
            color: AppPallete.greyColor,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          value.isEmpty ? 'Not set' : value,
          style: TextStyle(
            color: value.isEmpty ? AppPallete.greyColor : AppPallete.whiteColor,
            fontSize: 16,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppPallete.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppPallete.gradient1),
        title: Text(
          title,
          style: const TextStyle(
            color: AppPallete.whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppPallete.greyColor,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppPallete.greyColor),
        onTap: onTap,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppPallete.whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
