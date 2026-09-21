import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_entry.dart';
import '../providers/app_provider.dart';
import '../services/chat_service.dart';
import '../services/ai_provider_service.dart';
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
  final _providerService = AiProviderService();
  final _geminiService = GeminiService();
  AiProviderConfig? _aiConfig;
  bool _isTyping = false;
  bool _isLoading = true;

  static const _systemPrompt = '''
You are the AIDHD support assistant.

Only discuss ADHD-related focus, routines, organization, study strategies,
emotional regulation, and general educational support.

You are AIDHD, a proactive daily support companion, not a generic question-
answering chatbot. Begin by checking in on how the user feels today. Use the
most recent mood, daily assessment, and initial assessment only as supportive
context. Never treat those results as a diagnosis.

Do not diagnose ADHD. Do not prescribe medication or give treatment
instructions. Do not pretend to be a doctor. For medical or treatment
questions, recommend speaking with a qualified healthcare professional.

The user is 13 or older. Use supportive, practical, concise language. Do not
make assumptions about the user's diagnosis. If the user mentions immediate
danger or self-harm, encourage contacting local emergency services or a crisis
line immediately.

Keep each response warm and concise. Reflect one relevant detail, ask one
gentle question, and offer no more than one small action the user can try now.
Avoid repeating the same greeting or advice. If the user seems overwhelmed,
reduce the task to a two-minute step and celebrate starting rather than
completion.
''';

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
      _aiConfig = await _ensureAiConfig();
      if (records.isNotEmpty) {
        _messages.addAll(records.map((record) => _Message(
              id: record.id,
              isUser: record.isUser,
              text: record.text,
              time: record.time,
            )));
        if (_aiConfig != null &&
            await _providerService.needsDailyCheckIn(userId)) {
          final checkIn = await _generateOpeningMessage(app);
          await _addAssistantMessage(userId, checkIn, prefix: 'checkin');
          await _providerService.markDailyCheckIn(userId);
        }
      } else {
        final greeting = _aiConfig == null
            ? _buildGreeting(app)
            : await _generateOpeningMessage(app);
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
        if (_aiConfig != null) await _providerService.markDailyCheckIn(userId);
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
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<AiProviderConfig?> _ensureAiConfig({bool replace = false}) async {
    final userId = context.read<AppProvider>().currentUser?.id;
    if (userId == null) return null;
    if (!replace) {
      final saved = await _providerService.getConfig(userId);
      if (saved != null) return saved;
    }
    if (!mounted) return null;
    final saved = await _providerService.getConfig(userId);
    if (!mounted) return null;
    var provider = saved?.provider ?? AiProvider.gemini;
    final providerController = ValueNotifier<AiProvider>(provider);
    final keyController = TextEditingController(text: saved?.apiKey ?? '');
    final modelController = TextEditingController(
        text: saved?.model ?? AiProviderConfig.defaultModel(provider));
    final endpointController = TextEditingController(
        text: saved?.endpoint ?? AiProviderConfig.defaultEndpoint(provider));
    final config = await showDialog<AiProviderConfig>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(replace ? 'Change AI provider' : 'Connect AI chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an AI provider and paste its API key. The key stays on this device and your existing chat history is preserved.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<AiProvider>(
              valueListenable: providerController,
              builder: (_, selected, __) => DropdownButtonFormField<AiProvider>(
                initialValue: selected,
                decoration: const InputDecoration(
                    labelText: 'AI provider', border: OutlineInputBorder()),
                items: AiProvider.values
                    .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(AiProviderConfig(
                          provider: item,
                          apiKey: '',
                          model: '',
                          endpoint: '',
                        ).providerLabel)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  providerController.value = value;
                  modelController.text = AiProviderConfig.defaultModel(value);
                  endpointController.text =
                      AiProviderConfig.defaultEndpoint(value);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Gemini API key',
                hintText: 'Paste API key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                  labelText: 'Model', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endpointController,
              decoration: const InputDecoration(
                  labelText: 'API endpoint', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          if (replace)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          FilledButton(
            onPressed: () {
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                Navigator.pop(
                    dialogContext,
                    AiProviderConfig(
                      provider: providerController.value,
                      apiKey: key,
                      model: modelController.text.trim(),
                      endpoint: endpointController.text.trim(),
                    ));
              }
            },
            child: const Text('Save key'),
          ),
        ],
      ),
    );
    providerController.dispose();
    keyController.dispose();
    modelController.dispose();
    endpointController.dispose();
    if (config == null) return null;
    await _providerService.saveConfig(userId, config);
    return config;
  }

  Future<String> _generateOpeningMessage(AppProvider app) async {
    try {
      return await _geminiService.sendMessage(
        config: _aiConfig!,
        systemPrompt: _systemPrompt,
        history: const [],
        message: '''You are opening today's AIDHD check-in. Use this context:
${jsonEncode(app.buildAiContext())}

    Start with a natural, human-sounding check-in. Mention only one relevant
    observation from the latest mood or daily assessment, if available. Briefly
    connect it to their initial assessment only when useful. Then ask how they feel
    right now and offer one small ADHD-friendly coping step. Do not list all of the
    stored data, use clinical labels, or say that you are an AI.''',
      );
    } on GeminiException catch (error) {
      if (error.keyProblem) _aiConfig = await _ensureAiConfig(replace: true);
      return _buildGreeting(app);
    }
  }

  Future<void> _addAssistantMessage(String userId, String text,
      {String prefix = 'a'}) async {
    final message = _Message(
      id: '${prefix}_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text: text,
      time: _now(),
    );
    if (!mounted) return;
    setState(() => _messages.add(message));
    await _persistMessage(userId, message);
    _scrollToBottom();
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
        ? 'Before we plan anything, how are you feeling today? We can take one small step together.'
        : '${parts.join(', and ')}. How are you feeling right now? We can choose one small next step together.';
    return 'Hi${name.isNotEmpty ? " $name" : ""}. I\'m your AIDHD check-in companion. $contextLine';
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
    _aiConfig ??= await _ensureAiConfig();
    if (_aiConfig == null) return;
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
        config: _aiConfig!,
        systemPrompt: _systemPrompt,
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
      if (error.keyProblem) {
        _aiConfig = await _ensureAiConfig(replace: true);
      }
      setState(() {
        _messages.add(_Message(
          id: 'e${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: error.keyProblem
              ? 'Your Gemini key needs attention. Add a working key to continue; your chat history is still here.'
              : error.message,
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
        actions: [
          IconButton(
            tooltip: 'Replace Gemini API key',
            icon: const Icon(Icons.key_outlined),
            onPressed: () async {
              final config = await _ensureAiConfig(replace: true);
              if (config != null && mounted) setState(() => _aiConfig = config);
            },
          ),
        ],
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
