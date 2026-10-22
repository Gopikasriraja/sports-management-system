import 'package:cloud_functions/cloud_functions.dart';

abstract interface class ChatRepository {
  Future<String> ask({
    required String message,
    required List<Map<String, String>> history,
  });
}

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFunctions _functions;

  FirebaseChatRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<String> ask({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final callable = _functions.httpsCallable(
      'sportsAssistant',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 55)),
    );
    final result = await callable.call({
      'message': message,
      'history': history,
    });
    final data = result.data;
    if (data is! Map) {
      throw const FormatException(
        'The assistant returned an invalid response.',
      );
    }

    final rawAnswer = data['answer'];
    if (rawAnswer is! String) {
      throw const FormatException(
        'The assistant returned an invalid response.',
      );
    }
    final answer = rawAnswer.trim();
    if (answer.isEmpty) {
      throw const FormatException('The assistant returned an empty response.');
    }
    return answer;
  }
}
