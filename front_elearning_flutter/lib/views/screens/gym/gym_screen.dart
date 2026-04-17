import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/providers.dart';
import '../../../core/result/result.dart';
import '../../../models/flashcard/flashcard_models.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_reveal.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';

final _masteredNotebookCardsProvider =
    FutureProvider.autoDispose<List<FlashcardModel>>((ref) async {
      final result = await ref
          .read(flashcardFeatureViewModelProvider)
          .masteredReviewCards();
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final _reviewStatisticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final result = await ref
          .read(flashcardFeatureViewModelProvider)
          .reviewStatistics();
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen> {
  late final AudioPlayer _audioPlayer;
  String _playingUrl = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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
    final asyncItems = ref.watch(_masteredNotebookCardsProvider);
    final asyncStats = ref.watch(_reviewStatisticsProvider);

    Future<void> onRefresh() async {
      await Future.wait([
        ref.refresh(_masteredNotebookCardsProvider.future),
        ref.refresh(_reviewStatisticsProvider.future),
      ]);
    }

    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Sổ tay từ vựng')),
      body: asyncItems.when(
        data: (items) {
          final stats = asyncStats.valueOrNull ?? const <String, dynamic>{};
          final masteredCount =
              (stats['masteredCount'] ?? stats['MasteredCount'] ?? items.length)
                  .toString();
          final totalCards =
              (stats['totalCards'] ?? stats['TotalCards'] ?? items.length)
                  .toString();

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyStateView(
                    message: 'Sổ tay từ vựng đang trống',
                    icon: Icons.menu_book_outlined,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                CatalunyaReveal(
                  child: CatalunyaCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
                            ),
                          ),
                          child: const Icon(
                            Icons.book_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${items.length} từ đã lưu trong sổ tay',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kéo xuống để làm mới dữ liệu',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CatalunyaReveal(
                  delay: const Duration(milliseconds: 60),
                  child: Row(
                    children: [
                      Expanded(
                        child: CatalunyaCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đã thuộc',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                masteredCount,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CatalunyaCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tổng thẻ',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalCards,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return CatalunyaReveal(
                    delay: Duration(milliseconds: 45 * index),
                    child: CatalunyaCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFEAF5FF),
                            child: Icon(Icons.translate_rounded),
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
                                        item.term,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                    if (item.audioUrl.isNotEmpty)
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Phát âm',
                                        icon: Icon(
                                          _playingUrl == item.audioUrl &&
                                                  _audioPlayer.playing
                                              ? Icons.stop_circle_outlined
                                              : Icons.volume_up_rounded,
                                        ),
                                        onPressed: () =>
                                            _playAudio(item.audioUrl),
                                      ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF5FF),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        item.partOfSpeech,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.pronunciation.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '/${item.pronunciation}/',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF0A84FF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  item.definition.isEmpty
                                      ? 'Đã thuộc'
                                      : item.definition,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Đã thuộc',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: const Color(0xFF16A34A),
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
            ),
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}
