import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  const ChatPage({super.key, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _service = ChatService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  bool _sending = false;
  List<Map<String, Object?>> _messages = [];

  // ✅ gợi ý mới theo "học tập"
  final _suggestions = const [
    'Tuần trước học môn gì?',
    'Hôm qua có bài tập gì?',
    'Bài kiểm tra lần trước mấy điểm?',
    'Xem lịch thi',
    'Gia hạn học phí',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool keepScroll = true}) async {
    setState(() => _loading = true);
    _messages = await _service.getMessages(widget.userId);
    setState(() => _loading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (keepScroll) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _ctrl.clear();

    await _service.sendUserMessage(userId: widget.userId, text: text);
    await _load();

    setState(() => _sending = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ✅ thanh gợi ý đẹp hơn
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(s),
                    onPressed: () => _send(s),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    backgroundColor: cs.surfaceContainerHighest,
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final sender = (m['sender'] as String?) ?? 'bot';
              final text = (m['text'] as String?) ?? '';
              final isUser = sender == 'user';

              return _ChatBubble(
                isUser: isUser,
                text: text,
              );
            },
          ),
        ),

        const Divider(height: 1),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText:
                      'Nhập câu hỏi... (vd: Tuần trước học môn gì?)',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  width: 46,
                  child: FilledButton(
                    onPressed: _sending ? null : () => _send(),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const _ChatBubble({
    required this.isUser,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bubbleColor = isUser ? cs.primaryContainer : cs.surfaceContainerHighest;
    final textColor = isUser ? cs.onPrimaryContainer : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primary.withOpacity(0.12),
              child: Icon(Icons.school_rounded, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                text,
                style: TextStyle(color: textColor, height: 1.3),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.tertiary.withOpacity(0.15),
              child: Icon(Icons.person_rounded, size: 16, color: cs.tertiary),
            ),
          ],
        ],
      ),
    );
  }
}
