import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_roles.dart';
import '../../providers/auth_provider.dart';

class ChatbotLauncher extends StatelessWidget {
  const ChatbotLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    if (role != AppRoles.admin &&
        role != AppRoles.manager &&
        role != AppRoles.sportsStaff &&
        role != AppRoles.student) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      heroTag: 'sportsAssistantLauncher',
      onPressed: () => context.push('/chat'),
      icon: const Icon(Icons.smart_toy_outlined),
      label: const Text('Sports Assistant'),
      tooltip: 'Open the MRCAS Sports Assistant',
    );
  }
}
