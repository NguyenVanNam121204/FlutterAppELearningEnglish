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
import 'package:google_fonts/google_fonts.dart';

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

    // Invalidate providers to refresh review and notebook data
    ref.invalidate(flashcardReviewSessionViewModelProvider);
    ref.invalidate(flashcardFeatureViewModelProvider);
    ref.invalidate(dueReviewCardsProvider);
    ref.invalidate(notebookViewModelProvider);

    // Also try to find and invalidate providers defined in screens
    // For example, the one in vocabulary_screen.dart (if accessible by name,
    // but the app/providers.dart is better for global ones)

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
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Học flashcard'),
        actions: [
          if (widget.moduleId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22D3EE),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Luyện phát âm',
                  onPressed: () => context.push(
                    '${RoutePaths.pronunciation}?moduleId=${widget.moduleId}',
                  ),
                  icon: const Icon(Icons.mic_rounded, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tiến độ Flashcard',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.index + 1} / ${state.cards.length}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: 8,
                        width:
                            (MediaQuery.of(context).size.width - 72) *
                            ((state.index + 1) / state.cards.length),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = math.min(constraints.maxWidth, 420.0);
                  final cardHeight = math.min(
                    constraints.maxHeight * 0.95,
                    650.0,
                  );

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: cardWidth,
                        maxHeight: cardHeight,
                      ),
                      child: IntrinsicHeight(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutQuart,
                          switchOutCurve: Curves.easeInQuart,
                          transitionBuilder: (child, animation) {
                            final offset = Tween<Offset>(
                              begin: Offset(_slideFromRight ? 0.2 : -0.2, 0),
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
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: state.index == 0
                          ? null
                          : () async {
                              await _stopAudio();
                              notifier.previous();
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            color: state.index == 0
                                ? Colors.grey
                                : const Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Trước',
                            style: TextStyle(
                              color: state.index == 0
                                  ? Colors.grey
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isCompleting
                          ? null
                          : () async {
                              final done = notifier.next();
                              if (done) {
                                await _handleComplete();
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isCompleting
                                ? 'Đang xử lý...'
                                : state.index == state.cards.length - 1
                                ? 'Hoàn thành'
                                : 'Tiếp theo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            state.index == state.cards.length - 1
                                ? Icons.check_circle_outline_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
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
      duration: const Duration(milliseconds: 400),
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
      partOfSpeech: widget.partOfSpeech,
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
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFront
                ? front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: back,
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
    required this.partOfSpeech,
    required this.isPlaying,
    required this.onPlayAudio,
  });

  final String word;
  final String frontSentence;
  final String imageUrl;
  final String partOfSpeech;
  final bool isPlaying;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative background patterns
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                      const Color(0xFF22D3EE).withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Hero(
                          tag: 'card-image-$imageUrl',
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _CardImage(imageUrl: imageUrl, height: 220),
                          ),
                        )
                      else
                        Container(
                          height: 130,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                size: 56,
                                color: Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No Image Available',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (onPlayAudio != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FlashcardAudioButton(
                              isPlaying: isPlaying,
                              onPressed: onPlayAudio!,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          if (partOfSpeech.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0EA5E9),
                                    Color(0xFF22D3EE),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0EA5E9,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                partOfSpeech.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            word,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (frontSentence.trim().isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.format_quote_rounded,
                                    color: const Color(
                                      0xFF0EA5E9,
                                    ).withValues(alpha: 0.3),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    frontSentence,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF334155),
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFF1F5F9),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(seconds: 2),
                          tween: Tween(begin: 0.0, end: 1.0),
                          onEnd: () {},
                          builder: (context, value, child) {
                            return Opacity(
                              opacity:
                                  0.5 +
                                  (math.sin(value * math.pi * 2) * 0.5).abs(),
                              child: child,
                            );
                          },
                          child: const Icon(
                            Icons.touch_app_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ẤN ĐỂ XEM CHI TIẾT',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
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
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                size: 60,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Hero(
                          tag: 'card-image-$imageUrl',
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _CardImage(
                              imageUrl: imageUrl,
                              height: 220,
                              isBack: true,
                            ),
                          ),
                        ),
                      if (onPlayAudio != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FlashcardAudioButton(
                              isPlaying: isPlaying,
                              onPressed: onPlayAudio!,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            word,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (pronunciation.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0EA5E9,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '/$pronunciation/',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: const Color(0xFF0369A1),
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFBAE6FD),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  definition,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                    height: 1.3,
                                  ),
                                ),
                                if (exampleTranslation.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 2,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBAE6FD),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    exampleTranslation,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF475569),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flip_camera_android_rounded,
                          size: 18,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'LẬT LẠI MẶT TRƯỚC',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
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

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.imageUrl,
    required this.height,
    this.isBack = false,
  });

  final String imageUrl;
  final double height;
  final bool isBack;

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
        color: isBack ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBack
              ? Colors.white.withValues(alpha: 0.3)
              : const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: resolvedUrl.isEmpty
            ? Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: isBack ? Colors.white70 : const Color(0xFF9CA3AF),
                ),
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: isBack ? Colors.white70 : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
      ),
    );
  }
}
