import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../app/config/app_config.dart';
import '../../../app/providers.dart';
import '../../../models/flashcard/flashcard_models.dart';
import '../../widgets/common/catalunya_scaffold.dart';
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
      <
        ({
          int value,
          String label,
          Color background,
          Color border,
          IconData icon,
        })
      >[
        (
          value: 1,
          label: 'Quên',
          background: Color(0xFFFEF2F2),
          border: Color(0xFFFCA5A5),
          icon: Icons.sentiment_very_dissatisfied_rounded,
        ),
        (
          value: 2,
          label: 'Hơi nhớ',
          background: Color(0xFFFFF7ED),
          border: Color(0xFFFDBA74),
          icon: Icons.sentiment_dissatisfied_rounded,
        ),
        (
          value: 3,
          label: 'Nhớ',
          background: Color(0xFFFEFCE8),
          border: Color(0xFFFDE047),
          icon: Icons.sentiment_neutral_rounded,
        ),
        (
          value: 4,
          label: 'Khá nhớ',
          background: Color(0xFFF0FDF4),
          border: Color(0xFF86EFAC),
          icon: Icons.sentiment_satisfied_rounded,
        ),
        (
          value: 5,
          label: 'Thuộc',
          background: Color(0xFFEFF6FF),
          border: Color(0xFF93C5FD),
          icon: Icons.sentiment_very_satisfied_rounded,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flashcardReviewSessionViewModelProvider.notifier).initialize();
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Hoàn thành mục tiêu!',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn đã hoàn thành tất cả các từ cần ôn tập cho hôm nay rồi. Tuyệt vời quá!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Quay lại trang chủ',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (state.isFinished) {
      final needsReview = state.cards.length - state.mastered;
      return CatalunyaScaffold(
        appBar: AppBar(
          title: const Text('Kết quả ôn tập'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 80,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 32),

              // Success Message
              Text(
                'Tuyệt vời!',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đã hoàn thành phiên ôn tập',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildStatItem(
                      'TỔNG CỘNG',
                      '${state.cards.length}',
                      const Color(0xFFF1F5F9),
                      const Color(0xFF475569),
                      Icons.layers_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatItem(
                      'ĐÃ THUỘC',
                      '${state.mastered}',
                      const Color(0xFFDCFCE7),
                      const Color(0xFF16A34A),
                      Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatItem(
                      'CẦN ÔN LẠI',
                      '$needsReview',
                      const Color(0xFFFEE2E2),
                      const Color(0xFFDC2626),
                      Icons.refresh_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Finish Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.pop(),
                      child: Center(
                        child: Text(
                          'Hoàn thành',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final card = state.cards[state.index];

    return CatalunyaScaffold(
      appBar: AppBar(
        title: Text('Ôn tập ${state.index + 1}/${state.cards.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                            Icons.history_edu_rounded,
                            size: 18,
                            color: Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tiến độ ôn tập',
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
                            (MediaQuery.of(context).size.width - 64) *
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
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth * 0.88).clamp(
                    280.0,
                    440.0,
                  );
                  final cardHeight = (constraints.maxHeight * 0.85).clamp(
                    340.0,
                    480.0,
                  );

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: cardWidth,
                        maxHeight: cardHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF000000,
                                ).withValues(alpha: 0.12),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: InkWell(
                              onTap: notifier.toggleCard,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: _ReviewFlipCard(
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
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
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
                  const SizedBox(height: 8),
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
                                icon: option.icon,
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

  Widget _buildStatItem(
    String label,
    String value,
    Color bg,
    Color textColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.7),
                letterSpacing: 0.5,
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (card.imageUrl.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _ReviewCardImage(imageUrl: card.imageUrl, height: 110),
              ),
            )
          else
            Container(
              height: 140,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          if (onPlayAudio != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FlashcardAudioButton(
                isPlaying: isPlaying,
                onPressed: onPlayAudio!,
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                'ẤN ĐỂ XEM ĐÁP ÁN',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (card.imageUrl.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _ReviewCardImage(imageUrl: card.imageUrl, height: 100),
              ),
            ),
          if (onPlayAudio != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FlashcardAudioButton(
                isPlaying: isPlaying,
                onPressed: onPlayAudio!,
              ),
            ),
          Text(
            card.term,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          if (card.pronunciation.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '/${card.pronunciation}/',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF0369A1),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (card.partOfSpeech.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                card.partOfSpeech.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  card.definition,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                if (card.exampleTranslation.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 2,
                    width: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    card.exampleTranslation,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
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
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
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
    this.icon,
  });

  final int value;
  final String label;
  final Color background;
  final Color border;
  final bool disabled;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: disabled ? 0.55 : 1,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: border.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: 20, color: border.withValues(alpha: 0.9))
              else
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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
