import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../../../../core/providers/firebase_providers.dart';
import '../../../nutrition/data/services/nutrition_api_service.dart';

class ChatSession {
  final String id;
  final String summary;
  final DateTime createdAt;

  ChatSession({required this.id, required this.summary, required this.createdAt});
}

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
  final List<ChatSession> sessions;
  final String? conversationId;
  final bool isConnecting;
  final bool isGenerating;
  final String? error;

  ChatState({
    this.messages = const [],
    this.sessions = const [],
    this.conversationId,
    this.isConnecting = true,
    this.isGenerating = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatSession>? sessions,
    String? conversationId,
    bool? isConnecting,
    bool? isGenerating,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      conversationId: conversationId ?? this.conversationId,
      isConnecting: isConnecting ?? this.isConnecting,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  WebSocketChannel? _channel;
  String _currentAiMessageId = '';

  String get _userId {
    return ref.read(firebaseAuthProvider).currentUser?.uid ?? 'guest';
  }

  @override
  ChatState build() {
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
      String wsUrl = 'ws://10.252.42.49:8000/ws/chat/$_userId';
      if (state.conversationId != null) {
        wsUrl += '?conversation_id=${state.conversationId}';
      }
      final currentChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel = currentChannel;
      
      currentChannel.stream.listen(
        (data) => _handleMessage(data),
        onError: (err) {
          if (_channel != currentChannel) return; // Ignore if we intentionally reconnected
          state = state.copyWith(isConnecting: false, error: "Connection lost.");
          _reconnect();
        },
        onDone: () {
          if (_channel != currentChannel) return; // Ignore if we intentionally reconnected
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
        final cid = payload['conversation_id'] as String?;
        final List<dynamic> msgs = payload['messages'];
        final parsed = msgs.map((m) {
          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString() + m.hashCode.toString(),
            text: m['content'] ?? '',
            isUser: m['role'] == 'user',
            timestamp: DateTime.now(),
          );
        }).toList();
        state = state.copyWith(messages: parsed, conversationId: cid);
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
    
    // Refresh sessions after sending a message to ensure it appears in the history list
    if (state.messages.length <= 2) {
      Future.delayed(const Duration(seconds: 2), fetchSessions);
    }
  }

  Future<void> fetchSessions() async {
    try {
      final response = await http.get(Uri.parse('http://10.252.42.49:8000/api/v1/chat/sessions/$_userId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final sessions = data.map((s) => ChatSession(
          id: s['id'],
          summary: s['summary'],
          createdAt: DateTime.parse(s['created_at']),
        )).toList();
        state = state.copyWith(sessions: sessions);
      }
    } catch (e) {
      print("Failed to fetch sessions: $e");
    }
  }

  void startNewChat() {
    final oldChannel = _channel;
    _channel = null;
    oldChannel?.sink.close();
    
    state = ChatState(
      messages: [],
      sessions: state.sessions,
      conversationId: null, // explicitly null
      isConnecting: true,
      isGenerating: false,
      error: null,
    );
    _connect();
  }

  void loadSession(String conversationId) {
    if (state.conversationId == conversationId) return;
    
    final oldChannel = _channel;
    _channel = null;
    oldChannel?.sink.close();
    
    state = ChatState(
      messages: [],
      sessions: state.sessions,
      conversationId: conversationId,
      isConnecting: true,
      isGenerating: false,
      error: null,
    );
    _connect();
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
