enum ChatMessageRole { user, assistant }

class ChatMessage {
  final ChatMessageRole role;
  final String text;

  const ChatMessage({required this.role, required this.text});

  bool get isUser => role == ChatMessageRole.user;

  Map<String, String> toRequestMap() => {
    'role': isUser ? 'user' : 'model',
    'text': text,
  };
}
