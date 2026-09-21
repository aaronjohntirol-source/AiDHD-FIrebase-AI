import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_entry.dart';
import '../providers/app_provider.dart';
import '../services/chat_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class _Message {
  final String id;
  final bool isUser;
  final String text;
  final String time;
  _Message(
      {required this.id,
      required this.isUser,
      required this.text,
      required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  final _chatService = ChatService();
  final _geminiService = GeminiService();
  bool _isTyping = false;
  bool _isLoading = true;

  String _now() {
    final t = DateTime.now();
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    final app = context.read<AppProvider>();
    final userId = app.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final records = await _chatService.getMessages(userId);
      if (!mounted) return;
      if (records.isNotEmpty) {
        _messages.addAll(records.map((record) => _Message(
              id: record.id,
              isUser: record.isUser,
              text: record.text,
              time: record.time,
            )));
      } else {
        final greeting = await _generateOpeningMessage(app);
        final message = _Message(
          id: 'intro_${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: greeting,
          time: _now(),
        );
        _messages.add(message);
        await _chatService.saveMessage(
          userId: userId,
          id: message.id,
          isUser: false,
          text: message.text,
          time: message.time,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _messages.add(_Message(
        id: 'intro_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: _buildGreeting(app),
        time: _now(),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _generateOpeningMessage(AppProvider app) async {
    try {
      return await _geminiService.sendMessage(
        userContext: app.buildAiContext(),
        history: const [],
        message:
            '''Start this support conversation with the user. Use this context:
${jsonEncode(app.buildAiContext())}

Mention one relevant observation from their initial assessment, latest mood, or daily assessment if available. Offer one small coping step and ask how they are doing right now.''',
      );
    } on GeminiException catch (_) {
      return _buildGreeting(app);
    }
  }

  String _buildGreeting(AppProvider app) {
    final name = app.currentUser?.name ?? '';
    final moodEntries = app.history.where((entry) => entry.mood != null);
    final latestMood = moodEntries.isEmpty ? null : moodEntries.first.mood;
    final assessments = app.history
        .where((entry) => entry.type == EntryType.assessment && entry.isToday);
    final todayAssessment = assessments.isEmpty ? null : assessments.first;
    final parts = <String>[];
    if (latestMood != null) {
      parts.add(
          'You marked your mood as ${latestMood.displayName.toLowerCase()}');
    }
    if (todayAssessment != null) {
      parts.add('you completed today\'s assessment');
    }
    if (app.currentUser?.initialAssessmentCategory != null) {
      parts.add(
          'your initial screening was ${app.currentUser!.initialAssessmentCategory!.toLowerCase()}');
    }
    final contextLine = parts.isEmpty
        ? 'How are you feeling today, and what would be most useful to work on?'
        : '${parts.join(', and ')}. Would you like to talk through how today is going or choose one small next step?';
    return 'Hi${name.isNotEmpty ? " $name" : ""}! I\'m here with you. $contextLine';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _persistMessage(String userId, _Message message) async {
    try {
      await _chatService.saveMessage(
        userId: userId,
        id: message.id,
        isUser: message.isUser,
        text: message.text,
        time: message.time,
      );
    } catch (_) {
      // Chat remains usable if Firestore is temporarily unavailable.
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isTyping || _isLoading) return;
    final app = context.read<AppProvider>();
    final userId = app.currentUser?.id;
    if (userId == null) return;
    _ctrl.clear();
    final userMessage = _Message(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text,
      time: _now(),
    );
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    await _persistMessage(userId, userMessage);
    _scrollToBottom();

    try {
      final prompt = '''
User context:
${jsonEncode(app.buildAiContext())}

User message:
$text
''';
      final history = _messages
          .where((message) => message.id != userMessage.id)
          .where((message) => !message.id.startsWith('e'))
          .map((message) => {
                'role': message.isUser ? 'user' : 'model',
                'text': message.text,
              })
          .toList();
      final reply = await _geminiService.sendMessage(
        userContext: app.buildAiContext(),
        history: history,
        message: prompt,
      );
      final assistantMessage = _Message(
        id: 'a${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: reply,
        time: _now(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(assistantMessage);
      });
      await _persistMessage(userId, assistantMessage);
    } on GeminiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(
          id: 'e${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: error.message,
          time: _now(),
        ));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(
          id: 'e${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: 'The assistant is temporarily unavailable. Please try again.',
          time: _now(),
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => app.navigate(AppScreen.home)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AIDHD Assistant',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF22C55E), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Flexible(
                child: Text('Online · ADHD topics only',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w400))),
          ]),
        ]),
        centerTitle: false,
      ),
      body: Column(children: [
        // Privacy banner
        Container(
          color: const Color(0xFFF2F4F2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(children: [
            Icon(Icons.shield_outlined, size: 14, color: Color(0xFF49645D)),
            SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Conversations are private and used only to provide support.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMid))),
          ]),
        ),
        // Under-13 disclaimer banner
        if (app.isMinor)
          Container(
            color: const Color(0xFFFFF3CD),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Child-safe mode is active',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C5A00))),
                        SizedBox(height: 2),
                        Text(
                          'This AI uses age-appropriate language for users under 13 and will always suggest involving a trusted adult for health or treatment questions.',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7C5A00),
                              height: 1.5),
                        ),
                      ])),
                ]),
          ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (_isTyping && i == _messages.length) return _TypingBubble();
              final msg = _messages[i];
              return Align(
                alignment:
                    msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    border: msg.isUser
                        ? null
                        : Border.all(
                            color: AppColors.border.withValues(alpha: 0.4)),
                    boxShadow: msg.isUser
                        ? null
                        : [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                  ),
                  child: Column(
                      crossAxisAlignment: msg.isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(msg.text,
                            style: TextStyle(
                                fontSize: 14,
                                color: msg.isUser
                                    ? Colors.white
                                    : AppColors.textDark,
                                height: 1.5)),
                        const SizedBox(height: 4),
                        Text(msg.time,
                            style: TextStyle(
                                fontSize: 10,
                                color: msg.isUser
                                    ? Colors.white54
                                    : AppColors.textLight)),
                      ]),
                ),
              );
            },
          ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E8E4)))),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask about ADHD…',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F4),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: ValueListenableBuilder(
                  valueListenable: _ctrl,
                  builder: (_, val, __) {
                    final active = val.text.trim().isNotEmpty && !_isTyping;
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFE0E8E4),
                          shape: BoxShape.circle),
                      child: Icon(Icons.send,
                          size: 18,
                          color: active ? Colors.white : AppColors.textLight),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4)),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.33;
                  final t = (_ctrl.value - delay).clamp(0.0, 1.0);
                  final offset = -4.0 * (1 - (t * 2 - 1).abs());
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.textLight,
                                shape: BoxShape.circle))),
                  );
                })),
          ),
        ),
      );
}
