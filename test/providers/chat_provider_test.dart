import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sports_management_system/core/constants/app_roles.dart';
import 'package:sports_management_system/core/routes/app_router.dart';
import 'package:sports_management_system/models/user_model.dart';
import 'package:sports_management_system/database/repositories/chat_repository.dart';
import 'package:sports_management_system/models/chat_message.dart';
import 'package:sports_management_system/providers/auth_provider.dart';
import 'package:sports_management_system/providers/chat_provider.dart';
import 'package:sports_management_system/screens/chat/chatbot_screen.dart';

class _FakeChatRepository implements ChatRepository {
  String? error;
  final requests = <({String message, List<Map<String, String>> history})>[];

  @override
  Future<String> ask({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    requests.add((message: message, history: history));
    if (error != null) throw Exception(error);
    return 'Grounded answer';
  }
}

void main() {
  late _FakeChatRepository repository;
  late ChatProvider provider;

  setUp(() {
    repository = _FakeChatRepository();
    provider = ChatProvider(repository: repository);
  });

  tearDown(() {
    provider.dispose();
  });

  test('ignores empty input and adds a successful response', () async {
    await provider.sendMessage('  ');
    expect(repository.requests, isEmpty);
    expect(provider.messages, isEmpty);

    await provider.sendMessage('  When is attendance?  ');

    expect(repository.requests.single.message, 'When is attendance?');
    expect(provider.messages, hasLength(2));
    expect(provider.messages.first.role, ChatMessageRole.user);
    expect(provider.messages.last.text, 'Grounded answer');
    expect(provider.isLoading, isFalse);
  });

  test('retry repeats the failed question without duplicating it', () async {
    repository.error = 'network unavailable';
    await provider.sendMessage('Show my achievements');

    expect(provider.messages, hasLength(1));
    expect(provider.canRetry, isTrue);
    expect(provider.errorMessage, isNotNull);

    repository.error = null;
    await provider.retry();

    expect(repository.requests, hasLength(2));
    expect(provider.messages, hasLength(2));
    expect(provider.messages.last.role, ChatMessageRole.assistant);
    expect(provider.errorMessage, isNull);
  });

  test('clear chat removes session history and retry state', () async {
    repository.error = 'temporary failure';
    await provider.sendMessage('Show my attendance');

    provider.clearChat();

    expect(provider.messages, isEmpty);
    expect(provider.errorMessage, isNull);
    expect(provider.canRetry, isFalse);
  });

  test('app router builds with the authenticated chat route', () {
    expect(AppRouter.router, isA<GoRouter>());
  });

  testWidgets('chat screen displays suggestions and grounded responses', (
    tester,
  ) async {
    final chatRepository = _FakeChatRepository();
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        GoRoute(
          path: '/chat',
          builder: (_, _) => ChatbotScreen(repository: chatRepository),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _FakeAuthProvider(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How can I check my sports attendance?'), findsOneWidget);
    await tester.tap(find.text('How can I check my sports attendance?'));
    await tester.pumpAndSettle();

    expect(find.text('Grounded answer'), findsOneWidget);
    expect(find.text('Sports Assistant'), findsOneWidget);
  });
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider();

  @override
  UserModel? get currentUser => UserModel(
    uid: 'student-uid',
    name: 'Test Student',
    email: 'student@example.test',
    role: AppRoles.student,
    department: '',
    year: '',
    registerNumber: 'TEST001',
    phone: '',
    profileImage: '',
    status: 'active',
    createdAt: DateTime(2025),
  );
}
