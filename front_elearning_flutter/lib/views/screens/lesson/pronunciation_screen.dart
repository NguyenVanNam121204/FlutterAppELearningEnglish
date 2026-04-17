import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_nav_tile.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể phát audio mẫu')));
    }
  }

  @override
  void dispose() {
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

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _PronunciationSummaryCard(
                summaryAsync: asyncSummary,
                onStart: () => context.push(
                  '${RoutePaths.pronunciationDetail}?moduleId=${widget.moduleId}&startIndex=0',
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(list.length, (index) {
                final p = list[index];
                final audio = p.audioUrl;
                final practiced = p.progress.hasPracticed;
                final scoreText = practiced
                    ? 'Điểm tốt nhất: ${p.progress.bestScore.toStringAsFixed(1)}'
                    : 'Chưa luyện';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CatalunyaNavTile(
                    title: p.word,
                    subtitle: p.phonetic.isEmpty
                        ? scoreText
                        : '/${p.phonetic}/ • $scoreText',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (audio.isNotEmpty)
                          IconButton(
                            tooltip: 'Nghe phát âm',
                            icon: Icon(
                              _playingUrl == audio && _audioPlayer.playing
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_outlined,
                            ),
                            onPressed: () => _playAudio(audio),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              p.progress.status,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            p.progress.status,
                            style: TextStyle(
                              color: _statusColor(p.progress.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.push(
                      '${RoutePaths.pronunciationDetail}?moduleId=${widget.moduleId}&startIndex=$index',
                    ),
                  ),
                );
              }),
            ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lộ trình phát âm',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          summaryAsync.when(
            data: (summary) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  label: 'Đã luyện',
                  value: '${summary.totalPracticed}/${summary.totalFlashcards}',
                ),
                _SummaryChip(
                  label: 'Đã thuộc',
                  value: '${summary.masteredCount}',
                ),
                _SummaryChip(
                  label: 'Điểm TB',
                  value: summary.averageScore.toStringAsFixed(1),
                ),
                _SummaryChip(
                  label: 'Xếp loại',
                  value: summary.grade.isEmpty ? '-' : summary.grade,
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 4),
            ),
            error: (_, _) => const Text(
              'Không tải được thống kê module',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 6,
                shadowColor: const Color(0x551E3A8A),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1D4ED8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onStart,
              icon: const Icon(Icons.graphic_eq_rounded),
              label: const Text(
                'Bắt đầu luyện ngay',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
