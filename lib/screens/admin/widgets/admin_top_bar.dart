import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/mrcas_brand_mark.dart';
import '../../../core/widgets/theme_mode_button.dart';
import '../../../providers/auth_provider.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final bool isMobile;

  const AdminTopBar({
    super.key,
    required this.onMenuPressed,
    required this.isMobile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name ?? 'Account';
    final width = MediaQuery.sizeOf(context).width;
    final showBrandTitle = width >= 760;
    final showProfileName = width >= 940;

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .5)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onMenuPressed,
              tooltip: isMobile ? 'Open navigation' : 'Toggle navigation',
              icon: Icon(isMobile ? Icons.menu_rounded : Icons.menu_open_rounded),
            ),
            if (showBrandTitle) ...[
              const SizedBox(width: 8),
              const MrcasBrandMark(size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MRCAS',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Sports Management',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ] else
              const Spacer(),
            if (showProfileName) ...[
              CircleAvatar(
                radius: 17,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text(name.isEmpty ? 'A' : name[0].toUpperCase()),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
            const ThemeModeButton(),
            IconButton(
              tooltip: 'Log out',
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
