import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_reveal.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';

class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({super.key});

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  late final AudioPlayer _audioPlayer;
  String _playingUrl = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    Future.microtask(() {
      ref.read(notebookViewModelProvider.notifier).loadNotebookData();
    });
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      if (_audioPlayer.playing && _playingUrl == audioUrl) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() => _playingUrl = '');
        return;
      }

      _playingUrl = audioUrl;
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát audio từ vựng')),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notebookViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leadingBadgeBg = isDark
        ? const Color(0xFF243247)
        : const Color(0xFFEAF5FF);
    final leadingBadgeIcon = isDark
        ? const Color(0xFFBFDBFE)
        : const Color(0xFF0A84FF);
    final partOfSpeechBg = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFEAF5FF);
    final partOfSpeechFg = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF334155);
    final pronunciationColor = isDark
        ? const Color(0xFF7DD3FC)
        : const Color(0xFF0A84FF);

    Future<void> onRefresh() async {
      await ref.read(notebookViewModelProvider.notifier).refresh();
    }

    if (state.isLoading && state.items.isEmpty) {
      return const CatalunyaScaffold(appBar: null, body: LoadingStateView());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return CatalunyaScaffold(
        appBar: AppBar(title: const Text('Sổ tay từ vựng')),
        body: ErrorStateView(message: state.errorMessage!),
      );
    }

    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Sổ tay từ vựng')),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: Builder(
          builder: (context) {
            final items = state.items;

            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyStateView(
                    message: 'Sổ tay từ vựng đang trống',
                    icon: Icons.menu_book_outlined,
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                CatalunyaReveal(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Từ cần ôn hôm nay',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    items.length.toString(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 36,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2563EB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: items.isEmpty
                                ? null
                                : () =>
                                      context.push(RoutePaths.flashcardReview),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'BẮT ĐẦU ÔN TẬP',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách cần ôn',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items.length} từ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notebookItem = entry.value;
                  final flashcard = notebookItem.flashcard;
                  return CatalunyaReveal(
                    delay: Duration(milliseconds: 45 * index),
                    child: CatalunyaCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: leadingBadgeBg,
                            child: Icon(
                              Icons.translate_rounded,
                              color: leadingBadgeIcon,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        flashcard.term,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                    if (flashcard.audioUrl.isNotEmpty)
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Phát âm',
                                        icon: Icon(
                                          _playingUrl == flashcard.audioUrl &&
                                                  _audioPlayer.playing
                                              ? Icons.stop_circle_outlined
                                              : Icons.volume_up_rounded,
                                        ),
                                        onPressed: () =>
                                            _playAudio(flashcard.audioUrl),
                                      ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: partOfSpeechBg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        flashcard.partOfSpeech,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: partOfSpeechFg,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (flashcard.pronunciation
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '/${flashcard.pronunciation}/',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: pronunciationColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  flashcard.definition.isEmpty
                                      ? 'Đã thuộc'
                                      : flashcard.definition,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      notebookItem.isMastered
                                          ? Icons.check_circle_rounded
                                          : Icons.pending_actions_rounded,
                                      size: 16,
                                      color: notebookItem.isMastered
                                          ? const Color(0xFF16A34A)
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      notebookItem.isMastered
                                          ? 'Đã thuộc'
                                          : 'Đang học',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: notebookItem.isMastered
                                                ? const Color(0xFF16A34A)
                                                : Colors.orange,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
