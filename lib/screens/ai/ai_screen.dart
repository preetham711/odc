import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../models/attendance_model.dart';

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final _msgController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final question = text.trim();
    _msgController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _isThinking = true;
    });

    // Build context from real data
    final answer = await _generateAnswer(question);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: answer, isUser: false));
        _isThinking = false;
      });
    }
  }

  Future<String> _generateAnswer(String question) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return 'Please log in to get insights.';

    // Fetch real data
    final svc = ref.read(firestoreServiceProvider);
    final today = await svc.getTodayAttendance(uid);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    List<AttendanceModel> weekData = [];
    List<AttendanceModel> monthData = [];
    try {
      weekData = await svc.getAttendanceByDateRange(
          uid, DateTimeUtils.startOfDay(weekStart), DateTimeUtils.endOfDay(now));
      monthData = await svc.getAttendanceByDateRange(
          uid, monthStart, DateTimeUtils.endOfDay(now));
    } catch (_) {}

    final q = question.toLowerCase();

    // Today queries
    if (q.contains('today') || q.contains('current')) {
      if (today == null) {
        return "You haven't checked in today yet. Head to the Dashboard to start your shift!";
      }
      final odcTime = ref.read(currentODCTimeProvider);
      final breakTime = ref.read(currentBreakTimeProvider);
      final pct = ref.read(completionPercentageProvider);
      return "📊 Today's Summary:\n"
          "• ODC Time: ${DateTimeUtils.formatDuration(odcTime)}\n"
          "• Break Time: ${DateTimeUtils.formatDuration(breakTime)}\n"
          "• Goal Progress: ${pct.toStringAsFixed(1)}%\n"
          "• Status: ${today.isActive ? (ref.read(isOnBreakProvider) ? 'On Break ☕' : 'Working 🟢') : 'Shift ended ✅'}\n"
          "${pct >= 100 ? '\n🎉 You\'ve completed your 8-hour goal today!' : '\n⏱ ${DateTimeUtils.formatDuration((480 - odcTime).clamp(0, 480))} remaining to reach your goal.'}";
    }

    // Hours worked
    if (q.contains('hour') || q.contains('work') || q.contains('time')) {
      if (today == null) return "You haven't worked today yet.";
      final odcTime = ref.read(currentODCTimeProvider);
      return "You've worked ${DateTimeUtils.formatDuration(odcTime)} today out of your 8-hour goal (${(odcTime / 480 * 100).toStringAsFixed(0)}% complete).";
    }

    // Weekly queries
    if (q.contains('week')) {
      if (weekData.isEmpty) return "No data recorded this week yet.";
      final total =
          weekData.fold(0, (sum, a) => sum + a.odcTime);
      final avg = total ~/ weekData.length;
      final perfectDays =
          weekData.where((a) => a.completionPercentage >= 100).length;
      return "📅 This Week (${weekData.length} days recorded):\n"
          "• Total ODC: ${DateTimeUtils.formatDuration(total)}\n"
          "• Daily Average: ${DateTimeUtils.formatDuration(avg)}\n"
          "• Goal days achieved: $perfectDays/${weekData.length}\n"
          "${avg >= 480 ? '✅ Great work! You\'re meeting your daily goal on average.' : '⚠️ Average is below 8 hours. Try to be consistent!'}";
    }

    // Monthly queries
    if (q.contains('month')) {
      if (monthData.isEmpty) return "No data recorded this month yet.";
      final total =
          monthData.fold(0, (sum, a) => sum + a.odcTime);
      final avg = total ~/ monthData.length;
      final perfectDays =
          monthData.where((a) => a.completionPercentage >= 100).length;
      return "📆 This Month (${monthData.length} days):\n"
          "• Total ODC: ${DateTimeUtils.formatDuration(total)}\n"
          "• Daily Average: ${DateTimeUtils.formatDuration(avg)}\n"
          "• Perfect days: $perfectDays/${monthData.length}\n"
          "• Completion rate: ${(perfectDays / monthData.length * 100).toStringAsFixed(0)}%";
    }

    // Average
    if (q.contains('average') || q.contains('avg')) {
      if (weekData.isEmpty) return "No data yet to calculate averages.";
      final weekAvg =
          weekData.fold(0, (sum, a) => sum + a.odcTime) ~/ weekData.length;
      return "Your weekly average is ${DateTimeUtils.formatDuration(weekAvg)} per day."
          "${weekAvg >= 480 ? ' You\'re consistently hitting your goal! 🌟' : ' Aim for 8h daily to hit your target.'}";
    }

    // Target / goal
    if (q.contains('target') || q.contains('goal') ||
        q.contains('complet') || q.contains('achiev')) {
      if (today == null) return "Start your shift to track progress toward today's goal.";
      final odcTime = ref.read(currentODCTimeProvider);
      final pct = (odcTime / 480 * 100).clamp(0.0, 100.0);
      final weekGoalDays =
          weekData.where((a) => a.completionPercentage >= 100).length;
      return "🎯 Goal Progress:\n"
          "• Today: ${pct.toStringAsFixed(1)}% (${DateTimeUtils.formatDuration(odcTime)} / 8h)\n"
          "• This week: $weekGoalDays/${weekData.length} goal days\n"
          "${pct >= 100 ? '✅ Today\'s goal complete!' : '⏳ ${DateTimeUtils.formatDuration((480 - odcTime).clamp(0, 480))} left today.'}";
    }

    // Break queries
    if (q.contains('break')) {
      if (today == null) return "No break data for today yet.";
      final breakTime = ref.read(currentBreakTimeProvider);
      final breaks =
          today.sessions.where((s) => s.type == 'break').length;
      return "☕ Break Summary:\n"
          "• Total break time: ${DateTimeUtils.formatDuration(breakTime)}\n"
          "• Number of breaks: $breaks\n"
          "• Break limit: 60 min\n"
          "${breakTime > 60 ? '⚠️ You\'ve exceeded your break limit by ${DateTimeUtils.formatDuration(breakTime - 60)}.' : '✅ You\'re within your break limit.'}";
    }

    // Productivity suggestion
    if (q.contains('suggest') || q.contains('improve') ||
        q.contains('productiv')) {
      final odcTime =
          today != null ? ref.read(currentODCTimeProvider) : 0;
      final pct = odcTime / 480 * 100;
      final tips = <String>[];
      if (pct < 50) tips.add('• Start earlier to meet your 8h goal');
      if (monthData.isNotEmpty) {
        final avgBreak =
            monthData.fold(0, (s, a) => s + a.breakTime) ~/ monthData.length;
        if (avgBreak > 60) {
          tips.add('• Reduce break time — averaging ${DateTimeUtils.formatDuration(avgBreak)} daily');
        }
      }
      tips.add('• Use the Pomodoro technique: 25 min work, 5 min break');
      tips.add('• Take a short walk during breaks to stay energized');
      tips.add('• Stay hydrated — drink water every hour');
      return "💡 Productivity Tips for You:\n${tips.join('\n')}";
    }

    // Summary
    if (q.contains('summar')) {
      if (today == null) {
        return "No shift recorded today. Check in from the Dashboard!";
      }
      final odcTime = ref.read(currentODCTimeProvider);
      final breakTime = ref.read(currentBreakTimeProvider);
      final pct = ref.read(completionPercentageProvider);
      return "📋 Today's Summary — ${DateTimeUtils.formatDateLong(DateTime.now())}\n\n"
          "✅ Check-in: ${today.checkIn != null ? DateTimeUtils.formatTime12Hour(today.checkIn!) : 'N/A'}\n"
          "🏁 Check-out: ${today.checkOut != null ? DateTimeUtils.formatTime12Hour(today.checkOut!) : 'Ongoing'}\n"
          "⏱ ODC Time: ${DateTimeUtils.formatDuration(odcTime)}\n"
          "☕ Break Time: ${DateTimeUtils.formatDuration(breakTime)}\n"
          "📈 Progress: ${pct.toStringAsFixed(1)}%\n"
          "🔢 Sessions: ${today.sessions.length}";
    }

    return "I can answer questions about your attendance data. Try asking:\n"
        "• How many hours did I work today?\n"
        "• Show this week's summary\n"
        "• Am I completing my target?\n"
        "• Suggest productivity improvements\n"
        "• How much break time have I used?";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final quickPrompts = [
      'How many hours today?',
      "This week's summary",
      'Am I on target?',
      'Productivity tips',
      'Break time used',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AI Assistant'),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear chat',
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat Area ────────────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome(theme, quickPrompts)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _messages.length + (_isThinking ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isThinking && i == _messages.length) {
                        return _buildThinkingBubble(theme);
                      }
                      return _buildBubble(theme, _messages[i]);
                    },
                  ),
          ),

          // ── Quick Prompts (show when no messages) ────────────────────
          if (_messages.isEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: quickPrompts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(quickPrompts[i]),
                  onPressed: () => _sendMessage(quickPrompts[i]),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Input Bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your attendance…',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _sendMessage(_msgController.text),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(ThemeData theme, List<String> prompts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.primaryBlue.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 48, color: AppTheme.primaryBlue),
                const SizedBox(height: 12),
                Text('Your Attendance AI',
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Ask me anything about your work hours, breaks, and productivity. I use your real Firestore data.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Try asking…',
                style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          ...prompts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _sendMessage(p),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            color: AppTheme.primaryBlue, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(p,
                                style: theme.textTheme.bodyMedium)),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBubble(ThemeData theme, _ChatMessage msg) {
    return Align(
      alignment:
          msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppTheme.primaryBlue
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                Radius.circular(msg.isUser ? 16 : 4),
            bottomRight:
                Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: msg.isUser ? Colors.white : null),
        ),
      ),
    );
  }

  Widget _buildThinkingBubble(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(200),
            const SizedBox(width: 4),
            _dot(400),
          ],
        ),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
