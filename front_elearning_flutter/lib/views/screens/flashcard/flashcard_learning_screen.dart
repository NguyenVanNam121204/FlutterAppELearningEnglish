import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/config/app_config.dart';
import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/flashcard/flashcard_audio_button.dart';

class FlashCardLearningScreen extends ConsumerStatefulWidget {
  const FlashCardLearningScreen({
    this.lessonId = '',
    this.moduleId = '',
    super.key,
  });
  final String lessonId;
  final String moduleId;

  @override
  ConsumerState<FlashCardLearningScreen> createState() =>
      _FlashCardLearningScreenState();
}

class _FlashCardLearningScreenState
    extends ConsumerState<FlashCardLearningScreen> {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<PlayerState>? _playerSubscription;
  int _lastIndex = 0;
  bool _slideFromRight = true;
  bool _isPlaying = false;
  bool _isCompleting = false;
  String _playingUrl = '';

  Future<void> _handleComplete() async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
    });

    await _stopAudio();

    if (widget.moduleId.isNotEmpty) {
      await ref
          .read(lessonFeatureViewModelProvider)
          .startModule(widget.moduleId);

      final startResult = await ref
          .read(flashcardFeatureViewModelProvider)
          .startLearningModule(widget.moduleId);

      if (!mounted) return;

      if (startResult case Failure<void>(:final error)) {
        setState(() {
          _isCompleting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm từ vào danh sách ôn tập')),
    );
    Navigator.of(context).pop();
  }

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

  Future<void> _stopAudio() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.stop();
    }
    if (!mounted) return;
    setState(() {
      _playingUrl = '';
    });
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetKey = widget.moduleId.isNotEmpty
        ? 'module:${widget.moduleId}'
        : 'lesson:${widget.lessonId}';
    final state = ref.watch(flashcardLearningViewModelProvider(targetKey));
    final notifier = ref.read(
      flashcardLearningViewModelProvider(targetKey).notifier,
    );
    if (state.isLoading) {
      return const CatalunyaScaffold(body: LoadingStateView());
    }
    if (state.cards.isEmpty) {
      return CatalunyaScaffold(
        appBar: AppBar(title: Text('Học flashcard')),
        body: Center(
          child: EmptyStateView(
            message: 'Chưa có flashcard',
            icon: Icons.style_outlined,
          ),
        ),
      );
    }
    final c = state.cards[state.index];
    final word = c.term;
    final definition = c.definition;
    final pronunciation = c.pronunciation;
    final example = c.exampleSentence;
    final exampleTranslation = c.exampleTranslation;
    final partOfSpeech = c.partOfSpeech;
    final audioUrl = c.audioUrl;
    final imageUrl = c.imageUrl;

    if (_lastIndex != state.index) {
      _slideFromRight = state.index >= _lastIndex;
      _lastIndex = state.index;
    }
    return CatalunyaScaffold(
      appBar: AppBar(
        title: const Text('Học flashcard'),
        actions: [
          if (widget.moduleId.isNotEmpty)
            IconButton(
              tooltip: 'Luyện phát âm',
              onPressed: () => context.push(
                '${RoutePaths.pronunciation}?moduleId=${widget.moduleId}',
              ),
              icon: const Icon(Icons.mic_rounded),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.85),
                border: Border.all(color: const Color(0xFFD8E6F8)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${state.index + 1} / ${state.cards.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (state.index + 1) / state.cards.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = math.min(constraints.maxWidth * 0.9, 420.0);
                  final cardHeight = math.min(
                    constraints.maxHeight * 0.84,
                    560.0,
                  );

                  return Center(
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: Offset(_slideFromRight ? 0.16 : -0.16, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: _FlashcardFlipCard(
                          key: ValueKey('card-${state.index}'),
                          flipped: state.flipped,
                          word: word,
                          frontSentence: example,
                          pronunciation: pronunciation,
                          definition: definition,
                          partOfSpeech: partOfSpeech,
                          exampleTranslation: exampleTranslation,
                          imageUrl: imageUrl,
                          audioUrl: audioUrl,
                          isPlaying: _isPlaying && _playingUrl == audioUrl,
                          onToggle: notifier.toggleCard,
                          onPlayAudio: audioUrl.isEmpty
                              ? null
                              : () => _playAudio(audioUrl),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: state.index == 0
                        ? null
                        : () async {
                            await _stopAudio();
                            notifier.previous();
                          },
                    label: const Text('Trước'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(
                      state.index == state.cards.length - 1
                          ? Icons.check_circle_outline_rounded
                          : Icons.chevron_right_rounded,
                    ),
                    onPressed: _isCompleting
                        ? null
                        : () async {
                            final done = notifier.next();
                            if (done) {
                              await _handleComplete();
                            }
                          },
                    label: Text(
                      _isCompleting
                          ? 'Đang xử lý...'
                          : state.index == state.cards.length - 1
                          ? 'Hoàn thành'
                          : 'Tiếp theo',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardFlipCard extends StatefulWidget {
  const _FlashcardFlipCard({
    super.key,
    required this.flipped,
    required this.word,
    required this.frontSentence,
    required this.pronunciation,
    required this.definition,
    required this.partOfSpeech,
    required this.exampleTranslation,
    required this.imageUrl,
    required this.audioUrl,
    required this.isPlaying,
    required this.onToggle,
    required this.onPlayAudio,
  });

  final bool flipped;
  final String word;
  final String frontSentence;
  final String pronunciation;
  final String definition;
  final String partOfSpeech;
  final String exampleTranslation;
  final String imageUrl;
  final String audioUrl;
  final bool isPlaying;
  final VoidCallback onToggle;
  final VoidCallback? onPlayAudio;

  @override
  State<_FlashcardFlipCard> createState() => _FlashcardFlipCardState();
}

class _FlashcardFlipCardState extends State<_FlashcardFlipCard>
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
  void didUpdateWidget(covariant _FlashcardFlipCard oldWidget) {
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
    final front = _FrontCardFace(
      word: widget.word,
      frontSentence: widget.frontSentence,
      imageUrl: widget.imageUrl,
      isPlaying: widget.isPlaying,
      onPlayAudio: widget.onPlayAudio,
    );

    final back = _BackCardFace(
      word: widget.word,
      pronunciation: widget.pronunciation,
      definition: widget.definition,
      partOfSpeech: widget.partOfSpeech,
      exampleTranslation: widget.exampleTranslation,
      imageUrl: widget.imageUrl,
      isPlaying: widget.isPlaying,
      onPlayAudio: widget.onPlayAudio,
    );

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

          return SizedBox(
            width: double.infinity,
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: isFront
                  ? front
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: back,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _FrontCardFace extends StatelessWidget {
  const _FrontCardFace({
    required this.word,
    required this.frontSentence,
    required this.imageUrl,
    required this.isPlaying,
    required this.onPlayAudio,
  });

  final String word;
  final String frontSentence;
  final String imageUrl;
  final bool isPlaying;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DEE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onPlayAudio != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FlashcardAudioButton(
                        isPlaying: isPlaying,
                        onPressed: onPlayAudio!,
                      ),
                    ),
                  if (imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CardImage(imageUrl: imageUrl, height: 130),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: _CardImage(imageUrl: '', height: 110),
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
                      frontSentence.trim().isNotEmpty ? frontSentence : word,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        height: 1.32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ấn vào thẻ để lật',
                    style: TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackCardFace extends StatelessWidget {
  const _BackCardFace({
    required this.word,
    required this.pronunciation,
    required this.definition,
    required this.partOfSpeech,
    required this.exampleTranslation,
    required this.imageUrl,
    required this.isPlaying,
    required this.onPlayAudio,
  });

  final String word;
  final String pronunciation;
  final String definition;
  final String partOfSpeech;
  final String exampleTranslation;
  final String imageUrl;
  final bool isPlaying;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF7F9FC),
        border: Border.all(color: const Color(0xFFD7DEE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onPlayAudio != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FlashcardAudioButton(
                        isPlaying: isPlaying,
                        onPressed: onPlayAudio!,
                      ),
                    ),
                  if (imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CardImage(imageUrl: imageUrl, height: 120),
                    ),
                  Text(
                    word,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (pronunciation.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '/$pronunciation/',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (partOfSpeech.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      partOfSpeech,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (definition.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E6EF)),
                      ),
                      child: Text(
                        definition,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (exampleTranslation.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        exampleTranslation,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ấn vào thẻ để lật',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.imageUrl, required this.height});

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
