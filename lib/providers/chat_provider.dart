import 'package:flutter/foundation.dart';

import '../database/repositories/chat_repository.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final List<ChatMessage> _messages = [];

  ChatProvider({required this._repository});

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canRetry => _failedMessage != null && !_isLoading;

  bool _isLoading = false;
  String? _errorMessage;
  String? _failedMessage;

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(role: ChatMessageRole.user, text: message));
    _failedMessage = message;
    await _requestAnswer(message);
  }

  Future<void> retry() async {
    final message = _failedMessage;
    if (message == null || _isLoading) return;
    await _requestAnswer(message);
  }

  Future<void> _requestAnswer(String message) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final history = _messages
          .take(_messages.length - 1)
          .toList()
          .reversed
          .take(4)
          .toList()
          .reversed
          .map((entry) => entry.toRequestMap())
          .toList(growable: false);
      final answer = await _repository.ask(message: message, history: history);
      _messages.add(ChatMessage(role: ChatMessageRole.assistant, text: answer));
      _failedMessage = null;
    } catch (error) {
      _errorMessage = _messageForError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    if (_isLoading) return;
    _messages.clear();
    _errorMessage = null;
    _failedMessage = null;
    notifyListeners();
  }

  String _messageForError(Object error) {
    final text = error.toString();
    if (text.contains('resource-exhausted')) {
      return 'You have reached the assistant request limit. Please try again later.';
    }
    if (text.contains('unauthenticated')) {
      return 'Your sign-in has expired. Please sign in again to continue.';
    }
    if (text.contains('permission-denied')) {
      return 'Your account is not authorized to use the assistant.';
    }
    if (text.contains('unavailable') || text.contains('deadline-exceeded')) {
      return 'The assistant is temporarily unavailable. Check your connection and retry.';
    }
    return 'We could not get a response. Please retry.';
  }
}
