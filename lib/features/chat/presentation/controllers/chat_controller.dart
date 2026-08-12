import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../nutrition/data/services/nutrition_api_service.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  ChatMessage copyWith({String? text}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isConnecting;
  final bool isGenerating;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isConnecting = true,
    this.isGenerating = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnecting,
    bool? isGenerating,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  WebSocketChannel? _channel;
  String _currentAiMessageId = '';
  late String _userId;

  @override
  ChatState build() {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    _userId = user?.uid ?? 'guest';
    
    ref.onDispose(() {
      _channel?.sink.close();
    });

    Future.microtask(_connect);
    return ChatState(isConnecting: true);
  }

  void _connect() {
    state = state.copyWith(isConnecting: true, error: null);
    try {
      // Hardcode base url or read from config
      final wsUrl = 'ws://172.31.0.176:8000/ws/chat/$_userId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (err) {
          state = state.copyWith(isConnecting: false, error: "Connection lost.");
          _reconnect();
        },
        onDone: () {
          state = state.copyWith(isConnecting: false, error: "Disconnected.");
          _reconnect();
        },
      );
      state = state.copyWith(isConnecting: false);
    } catch (e) {
      state = state.copyWith(isConnecting: false, error: e.toString());
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      // Notifier's state access throws if disposed, but we can check if it has listeners or simply catch it.
      try {
        _connect();
      } catch (_) {}
    });
  }

  void _handleMessage(dynamic data) {
    try {
      final payload = jsonDecode(data as String);
      final type = payload['type'];

      if (type == 'history') {
        final List<dynamic> msgs = payload['messages'];
        final parsed = msgs.map((m) {
          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString() + m.hashCode.toString(),
            text: m['content'] ?? '',
            isUser: m['role'] == 'user',
            timestamp: DateTime.now(),
          );
        }).toList();
        state = state.copyWith(messages: parsed);
      } else if (type == 'stream_start') {
        _currentAiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
        final newMsg = ChatMessage(
          id: _currentAiMessageId,
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, newMsg],
          isGenerating: true,
        );
      } else if (type == 'stream_chunk') {
        final chunk = payload['content'] as String;
        final msgs = List<ChatMessage>.from(state.messages);
        final index = msgs.indexWhere((m) => m.id == _currentAiMessageId);
        if (index != -1) {
          msgs[index] = msgs[index].copyWith(text: msgs[index].text + chunk);
          state = state.copyWith(messages: msgs);
        }
      } else if (type == 'stream_end') {
        state = state.copyWith(isGenerating: false);
      } else if (type == 'error') {
        state = state.copyWith(error: payload['content']);
      }
    } catch (e) {
      print("Chat handle error: $e");
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty || _channel == null || state.isGenerating) return;

    // Add user message locally immediately
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMsg]);

    // Send to backend
    _channel!.sink.add(jsonEncode({'message': text}));
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
