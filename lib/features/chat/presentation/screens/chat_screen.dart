import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/chat_controller.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../widgets/chat_workout_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : context.customColors.grey900,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: context.colors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KRATOS AI',
                  style: AppTypography.labelBold.copyWith(
                    color: isDark ? Colors.white : context.customColors.grey900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  chatState.isConnecting ? 'Connecting...' : 'Online',
                  style: AppTypography.caption.copyWith(
                    color: chatState.isConnecting 
                        ? context.customColors.warning 
                        : context.customColors.success,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      body: Column(
        children: [
          if (chatState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              child: Text(
                chatState.error!,
                style: AppTypography.caption.copyWith(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return _buildMessageBubble(msg, isDark);
                    },
                  ),
          ),
          _buildInputArea(isDark, chatState.isGenerating),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, color: context.colors.primary, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Kratos AI Coach',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? Colors.white : context.customColors.grey900,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me to create a workout, adjust your macros,\nor explain a fitness concept.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white54 : context.customColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Create a Push day workout', isDark),
              _buildSuggestionChip('How much protein do I need?', isDark),
              _buildSuggestionChip('Explain progressive overload', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final bool isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: context.colors.primary, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser
                    ? context.colors.primary
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: !isUser
                    ? Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                      )
                    : null,
              ),
              child: _buildParsedContent(msg.text, isUser, isDark),
            ),
          ),
          if (isUser) const SizedBox(width: 38), // Balance spacing on right
        ],
      ),
    );
  }

  Widget _buildParsedContent(String text, bool isUser, bool isDark) {
    final regex = RegExp(r'```json_workout\s*(\{[\s\S]*?\})\s*```');
    final match = regex.firstMatch(text);
    
    if (match != null) {
      final before = text.substring(0, match.start).trim();
      final after = text.substring(match.end).trim();
      final jsonStr = match.group(1) ?? '{}';
      Map<String, dynamic> workoutData = {};
      try {
        workoutData = jsonDecode(jsonStr);
      } catch (_) {}

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (before.isNotEmpty) _buildTextBlock(before, isUser, isDark),
          if (workoutData.isNotEmpty)
            ChatWorkoutCard(
              workoutData: workoutData,
              onSave: () {
                // Here we would interact with Workout repository, for now visual feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Workout saved successfully!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          if (after.isNotEmpty) _buildTextBlock(after, isUser, isDark),
        ],
      );
    }
    
    // If typing is in progress and the JSON tag is being built, clean it to avoid ugly raw tags
    String cleanText = text;
    if (cleanText.contains('```json_workout')) {
      cleanText = cleanText.replaceAll(RegExp(r'```json_workout[\s\S]*'), 'Generating workout...');
    }
    
    return _buildTextBlock(cleanText, isUser, isDark);
  }

  Widget _buildTextBlock(String text, bool isUser, bool isDark) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        color: isUser
            ? Colors.white
            : (isDark ? Colors.white.withValues(alpha: 0.9) : context.customColors.grey900),
        height: 1.5,
      ),
    );
  }

  Widget _buildInputArea(bool isDark, bool isGenerating) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: _textController,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : context.customColors.grey900,
                ),
                decoration: InputDecoration(
                  hintText: 'Message Kratos AI...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white38 : context.customColors.grey500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
                enabled: !isGenerating,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isGenerating ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isGenerating
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : context.colors.primary,
                shape: BoxShape.circle,
                boxShadow: isGenerating
                    ? []
                    : [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatNotifierProvider.notifier).sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }
}
