import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/config/app_config.dart';
import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../models/flashcard/flashcard_models.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/flashcard/flashcard_audio_button.dart';

class FlashCardReviewSession extends ConsumerStatefulWidget {
  const FlashCardReviewSession({super.key});

  @override
  ConsumerState<FlashCardReviewSession> createState() =>
      _FlashCardReviewSessionState();
}

class _FlashCardReviewSessionState
    extends ConsumerState<FlashCardReviewSession> {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<PlayerState>? _playerSubscription;
  bool _isPlaying = false;
  String _playingUrl = '';

  static const _qualityOptions =
      <({int value, String label, Color background, Color border})>[
        (
          value: 1,
          label: 'Quên',
          background: Color(0xFFFEE2E2),
          border: Color(0xFFEF4444),
        ),
        (
          value: 2,
          label: 'Hơi nhớ',
          background: Color(0xFFFFEDD5),
          border: Color(0xFFF97316),
        ),
        (
          value: 3,
          label: 'Nhớ',
          background: Color(0xFFFEF9C3),
          border: Color(0xFFEAB308),
        ),
        (
          value: 4,
          label: 'Khá nhớ',
          background: Color(0xFFDCFCE7),
          border: Color(0xFF22C55E),
        ),
        (
          value: 5,
          label: 'Thuộc',
          background: Color(0xFFDBEAFE),
          border: Color(0xFF3B82F6),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playerSubscription = _audioPlayer.playerStateStream.listen((playerState) {
      if (!mounted) return;
      if (playerState.processingState == ProcessingState.completed) {
        _audioPlayer.stop();
      }
      setState(() {
        _isPlaying = playerState.playing;
      });
    });
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      if (_playingUrl == audioUrl && _audioPlayer.playing) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _playingUrl = '';
        });
        return;
      }

      _playingUrl = audioUrl;
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát âm thanh flashcard')),
      );
    }
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardReviewSessionViewModelProvider);
    final notifier = ref.read(flashcardReviewSessionViewModelProvider.notifier);
    if (state.isLoading) {
      return const CatalunyaScaffold(body: LoadingStateView());
    }
    if (state.cards.isEmpty) {
      return CatalunyaScaffold(
        appBar: AppBar(title: const Text('Ôn tập flashcard')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyStateView(
                message: 'Bạn đã hoàn thành bài ôn tập hôm nay',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.isFinished) {
      return CatalunyaScaffold(
        appBar: AppBar(title: const Text('Ôn tập flashcard')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
              const SizedBox(height: 8),
              const Text('Hoàn thành xuất sắc!'),
              const SizedBox(height: 8),
              Text('Tổng số từ vừa ôn: ${state.cards.length}'),
              Text(
                'Đã thuộc: ${state.mastered} • Cần ôn lại: ${state.cards.length - state.mastered}',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(RoutePaths.mainAppHome),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      );
    }
    final card = state.cards[state.index];

    final progress = (state.index + 1) / state.cards.length;

    return CatalunyaScaffold(
      appBar: AppBar(
        title: Text('Ôn tập ${state.index + 1}/${state.cards.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.88),
                border: Border.all(color: const Color(0xFFD8E6F8)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ ôn tập',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${state.index + 1}/${state.cards.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth * 0.88).clamp(
                    280.0,
                    440.0,
                  );
                  final cardHeight = (constraints.maxHeight * 0.82).clamp(
                    360.0,
                    620.0,
                  );

                  return Center(
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        elevation: 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: notifier.toggleCard,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFD6E3F5),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x190B4A8B),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _ReviewFlipCard(
                                    key: ValueKey('review-card-${state.index}'),
                                    card: card,
                                    flipped: state.showBack,
                                    isPlaying:
                                        _isPlaying &&
                                        _playingUrl == card.audioUrl,
                                    onToggle: notifier.toggleCard,
                                    onPlayAudio: card.audioUrl.trim().isEmpty
                                        ? null
                                        : () => _playAudio(card.audioUrl),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE8F8)),
              ),
              child: Column(
                children: [
                  Text(
                    'Bạn nhớ từ này thế nào?',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _qualityOptions
                        .map(
                          (option) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: _ReviewQualityButton(
                                value: option.value,
                                label: option.label,
                                background: option.background,
                                border: option.border,
                                disabled: state.isSubmitting,
                                onTap: () => notifier.review(option.value),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewFlipCard extends StatefulWidget {
  const _ReviewFlipCard({
    super.key,
    required this.card,
    required this.flipped,
    required this.isPlaying,
    required this.onToggle,
    required this.onPlayAudio,
  });

  final FlashcardModel card;
  final bool flipped;
  final bool isPlaying;
  final VoidCallback onToggle;
  final VoidCallback? onPlayAudio;

  @override
  State<_ReviewFlipCard> createState() => _ReviewFlipCardState();
}

class _ReviewFlipCardState extends State<_ReviewFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: widget.flipped ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _ReviewFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipped != widget.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final isFront = _controller.value <= 0.5;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFront
                ? _ReviewFrontFace(
                    card: widget.card,
                    isPlaying: widget.isPlaying,
                    onPlayAudio: widget.onPlayAudio,
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _ReviewBackFace(
                      card: widget.card,
                      isPlaying: widget.isPlaying,
                      onPlayAudio: widget.onPlayAudio,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ReviewFrontFace extends StatelessWidget {
  const _ReviewFrontFace({
    required this.card,
    required this.isPlaying,
    required this.onPlayAudio,
  });

  final FlashcardModel card;
  final bool isPlaying;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final frontSentence = card.exampleSentence.trim().isNotEmpty
        ? card.exampleSentence
        : card.term;

    return Column(
      children: [
        if (onPlayAudio != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FlashcardAudioButton(
              isPlaying: isPlaying,
              onPressed: onPlayAudio!,
            ),
          ),
        if (card.imageUrl.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ReviewCardImage(imageUrl: card.imageUrl, height: 170),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            frontSentence,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              height: 1.32,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ấn vào thẻ để lật',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black45),
        ),
      ],
    );
  }
}

class _ReviewBackFace extends StatelessWidget {
  const _ReviewBackFace({
    required this.card,
    required this.isPlaying,
    required this.onPlayAudio,
  });

  final FlashcardModel card;
  final bool isPlaying;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onPlayAudio != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FlashcardAudioButton(
              isPlaying: isPlaying,
              onPressed: onPlayAudio!,
            ),
          ),
        if (card.imageUrl.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewCardImage(imageUrl: card.imageUrl, height: 150),
          ),
        Text(
          card.term,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
          textAlign: TextAlign.center,
        ),
        if (card.pronunciation.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '/${card.pronunciation}/',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (card.partOfSpeech.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            card.partOfSpeech,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (card.definition.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E6EF)),
            ),
            child: Text(
              card.definition,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (card.exampleTranslation.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              card.exampleTranslation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF475569),
                height: 1.3,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Ấn vào thẻ để lật',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black45),
        ),
      ],
    );
  }
}

class _ReviewCardImage extends StatelessWidget {
  const _ReviewCardImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  String _resolveUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return trimmed;
    }

    final base = AppConfig.apiBaseUrl;
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    if (trimmed.startsWith('/')) {
      return '$normalizedBase$trimmed';
    }
    return '$normalizedBase/$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveUrl(imageUrl);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: resolvedUrl.isEmpty
            ? const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 38,
                  color: Color(0xFF94A3B8),
                ),
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 38,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ReviewQualityButton extends StatelessWidget {
  const _ReviewQualityButton({
    required this.value,
    required this.label,
    required this.background,
    required this.border,
    required this.disabled,
    required this.onTap,
  });

  final int value;
  final String label;
  final Color background;
  final Color border;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: disabled ? 0.55 : 1,
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
