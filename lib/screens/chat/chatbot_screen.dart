import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_roles.dart';
import '../../database/repositories/chat_repository.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatbotScreen extends StatelessWidget {
  final ChatRepository? repository;

  const ChatbotScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role;
    if (user == null ||
        (role != AppRoles.admin &&
            role != AppRoles.manager &&
            role != AppRoles.sportsStaff &&
            role != AppRoles.student)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/welcome');
      });
      return const Scaffold(
        body: Center(
          child: Text('Sign in with an authorized account to chat.'),
        ),
      );
    }

    return ChangeNotifierProvider(
      key: ValueKey(user.uid),
      create: (_) =>
          ChatProvider(repository: repository ?? FirebaseChatRepository()),
      child: const _ChatbotView(),
    );
  }
}

class _ChatbotView extends StatefulWidget {
  const _ChatbotView();

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'How can I check my sports attendance?',
    'What equipment is currently available?',
    'Are there any upcoming sports events?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    if (value.trim().isEmpty) return;
    _inputController.clear();
    final request = context.read<ChatProvider>().sendMessage(value);
    _scrollToBottom();
    await request;
    if (!mounted) return;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: const Icon(Icons.smart_toy_outlined),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sports Assistant'),
                  Text(
                    'MRCAS • role-aware guidance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chat, _) => IconButton(
              tooltip: 'Clear chat',
              onPressed: chat.isLoading ? null : chat.clearChat,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, chat, _) {
                      if (chat.messages.isEmpty) {
                        return _WelcomePanel(
                          suggestions: _suggestions,
                          onSelect: _submit,
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        itemCount:
                            chat.messages.length + (chat.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chat.messages.length) {
                            return const _TypingIndicator();
                          }
                          return _MessageBubble(message: chat.messages[index]);
                        },
                      );
                    },
                  ),
                ),
                Consumer<ChatProvider>(
                  builder: (context, chat, _) {
                    if (chat.errorMessage == null) {
                      return const SizedBox.shrink();
                    }
                    final signInAgain = chat.errorMessage!.contains(
                      'sign-in has expired',
                    );
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Material(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: signInAgain
                                    ? () => context.go('/welcome')
                                    : chat.canRetry
                                    ? chat.retry
                                    : null,
                                icon: Icon(
                                  signInAgain ? Icons.login : Icons.refresh,
                                ),
                                label: Text(signInAgain ? 'Sign in' : 'Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _MessageComposer(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  onSend: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  const _WelcomePanel({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 36),
          Icon(Icons.sports, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'How can I help with sports today?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'I can explain app workflows and answer using information your account is allowed to access.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () => onSelect(suggestion),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(suggestion, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Answers about live records depend on the available authorized data.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Your question and up to four recent messages are sent to the AI provider. '
            'Avoid entering sensitive personal details. Chat history stays on this screen only.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: message.isUser
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomRight: message.isUser ? const Radius.circular(4) : null,
              bottomLeft: message.isUser ? null : const Radius.circular(4),
            ),
          ),
          child: SelectableText(
            message.text,
            style: TextStyle(
              color: message.isUser
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Chip(
          avatar: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('Assistant is thinking…'),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSend;

  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                enabled: !chat.isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: chat.isLoading ? null : onSend,
                decoration: const InputDecoration(
                  hintText: 'Ask about sports, attendance, or equipment…',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: chat.isLoading ? null : () => onSend(controller.text),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
