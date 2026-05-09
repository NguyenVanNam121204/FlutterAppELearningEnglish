import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';

class PronunciationScreen extends ConsumerStatefulWidget {
  const PronunciationScreen({required this.moduleId, super.key});

  final String moduleId;

  @override
  ConsumerState<PronunciationScreen> createState() =>
      _PronunciationScreenState();
}

class _PronunciationScreenState extends ConsumerState<PronunciationScreen> {
  late final AudioPlayer _audioPlayer;
  String _playingUrl = '';
  StreamSubscription? _playerSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playerSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _playingUrl = '';
          });
        }
      }
    });
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      // 1. Kiểm tra nếu chính URL này đang phát thì dừng lại
      if (_audioPlayer.playing && _playingUrl == audioUrl) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _playingUrl = '');
        return;
      }

      // 2. Dừng bất kỳ âm thanh nào đang phát
      await _audioPlayer.stop();

      // 3. Xóa URL cũ hoàn toàn khỏi Player để tránh kẹt cache/buffer
      await _audioPlayer.seek(null);

      // 4. Bắt đầu phát URL mới
      _playingUrl = audioUrl;
      if (mounted) setState(() {}); // Hiện icon Stop ngay lập tức

      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();

      // 5. Sau khi play() kết thúc (phát xong), cập nhật UI
      if (mounted) setState(() => _playingUrl = '');
    } catch (e) {
      debugPrint('Audio error: $e');
      if (mounted) {
        setState(() => _playingUrl = '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể phát audio mẫu')),
        );
      }
    }
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(pronunciationListProvider(widget.moduleId));
    final asyncSummary = ref.watch(
      pronunciationSummaryProvider(widget.moduleId),
    );

    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Luyện phát âm')),
      body: asyncList.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: EmptyStateView(
                message: 'Không có dữ liệu phát âm',
                icon: Icons.graphic_eq_rounded,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _PronunciationSummaryCard(
                  summaryAsync: asyncSummary,
                  onStart: () => context.push(
                    '${RoutePaths.pronunciationDetail}?moduleId=${widget.moduleId}&startIndex=0',
                  ),
                );
              }

              final index = i - 1;
              final p = list[index];
              final audio = p.audioUrl;
              final practiced = p.progress.hasPracticed;
              final scoreText = practiced
                  ? 'Điểm tốt nhất: ${p.progress.bestScore.toStringAsFixed(1)}'
                  : 'Chưa luyện';

              return Material(
                color: Theme.of(context).cardColor,
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(
                    '${RoutePaths.pronunciationDetail}?moduleId=${widget.moduleId}&startIndex=$index',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0EA5E9,
                                ).withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              p.word.isNotEmpty ? p.word[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.word,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.phonetic.isEmpty
                                    ? scoreText
                                    : '/${p.phonetic}/ • $scoreText',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (audio.isNotEmpty)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _playAudio(audio),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(
                                          0xFF0EA5E9,
                                        ).withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF0EA5E9,
                                          ).withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: StreamBuilder<PlayerState>(
                                        stream: _audioPlayer.playerStateStream,
                                        builder: (context, snapshot) {
                                          final playerState = snapshot.data;
                                          final isPlaying =
                                              playerState?.playing ?? false;
                                          final isProcessing =
                                              (playerState?.processingState ==
                                                  ProcessingState.loading ||
                                              playerState?.processingState ==
                                                  ProcessingState.buffering);

                                          if (_playingUrl == audio &&
                                              isProcessing) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFF0EA5E9)),
                                              ),
                                            );
                                          }

                                          return Icon(
                                            _playingUrl == audio && isPlaying
                                                ? Icons.stop_rounded
                                                : Icons.volume_up_rounded,
                                            color: const Color(0xFF0EA5E9),
                                            size: 26,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  p.progress.status,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                p.progress.status,
                                style: TextStyle(
                                  color: _statusColor(p.progress.status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('master')) return const Color(0xFF10B981);
    if (s.contains('practic')) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }
}

class _PronunciationSummaryCard extends StatelessWidget {
  const _PronunciationSummaryCard({
    required this.summaryAsync,
    required this.onStart,
  });

  final AsyncValue summaryAsync;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lộ trình phát âm',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    summaryAsync.when(
                      data: (summary) => Text(
                        '${summary.totalPracticed}/${summary.totalFlashcards} từ đã luyện • Điểm TB ${summary.averageScore.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(minHeight: 6),
                      ),
                      error: (_, _) => const Text(
                        'Không tải được thống kê',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          summaryAsync.when(
            data: (summary) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value:
                              summary.totalPracticed /
                              (summary.totalFlashcards <= 0
                                  ? 1
                                  : summary.totalFlashcards),
                          minHeight: 10,
                          backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF22D3EE),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${summary.totalPracticed}/${summary.totalFlashcards}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      backgroundColor: const Color(0xFF0EA5E9),
                    ),
                    onPressed: onStart,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_arrow_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Bắt đầu luyện ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
