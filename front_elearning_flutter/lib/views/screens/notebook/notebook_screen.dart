import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../app/providers.dart';
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
  StreamSubscription<PlayerState>? _playerSubscription;
  String _playingUrl = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playerSubscription = _audioPlayer.playerStateStream.listen((playerState) {
      if (!mounted) return;
      if (playerState.processingState == ProcessingState.completed ||
          (playerState.processingState == ProcessingState.ready &&
              !playerState.playing &&
              _audioPlayer.position >= _audioPlayer.duration!)) {
        _audioPlayer.stop();
        _audioPlayer.seek(Duration.zero);
        setState(() => _playingUrl = '');
      } else {
        setState(() {});
      }
    });
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
      setState(() {});
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát audio từ vựng')),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danh sách từ vựng',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Lưu trữ kho báu kiến thức của bạn',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: leadingBadgeIcon.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: leadingBadgeIcon,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${items.length}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notebookItem = entry.value;
                  final flashcard = notebookItem.flashcard;

                  return CatalunyaReveal(
                    delay: Duration(milliseconds: 60 * index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Slidable(
                        key: ValueKey(flashcard.flashCardId),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            CustomSlidableAction(
                              onPressed: (context) {
                                // Add to favorites logic here
                              },
                              backgroundColor: Colors.transparent,
                              foregroundColor: const Color(0xFFFFB800),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB800,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(Icons.star_rounded, size: 28),
                              ),
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            CustomSlidableAction(
                              onPressed: (context) {
                                // Add to favorites logic here
                              },
                              backgroundColor: Colors.transparent,
                              foregroundColor: const Color(0xFFFF4D4D),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF4D4D,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFF1E293B),
                                      const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      const Color(0xFFF8FAFC),
                                      const Color(
                                        0xFFF1F5F9,
                                      ).withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : const Color(
                                        0xFFE2E8F0,
                                      ).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: leadingBadgeBg,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                leadingBadgeBg,
                                                leadingBadgeBg.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ],
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.translate_rounded,
                                            color: leadingBadgeIcon,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      flashcard.term,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF0F172A,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: partOfSpeechBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      flashcard.partOfSpeech
                                                          .toUpperCase(),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: partOfSpeechFg,
                                                        letterSpacing: 0.5,
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
                                                  style: GoogleFonts.inter(
                                                    color: pronunciationColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              Text(
                                                flashcard.definition.isEmpty
                                                    ? 'Chưa có định nghĩa'
                                                    : flashcard.definition,
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF334155),
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          notebookItem
                                                              .isMastered
                                                          ? const Color(
                                                              0xFFDCFCE7,
                                                            )
                                                          : const Color(
                                                              0xFFF3E8FF,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          notebookItem
                                                                  .isMastered
                                                              ? Icons
                                                                    .verified_rounded
                                                              : Icons
                                                                    .auto_awesome_rounded,
                                                          size: 14,
                                                          color:
                                                              notebookItem
                                                                  .isMastered
                                                              ? const Color(
                                                                  0xFF16A34A,
                                                                )
                                                              : const Color(
                                                                  0xFF9333EA,
                                                                ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          notebookItem
                                                                  .isMastered
                                                              ? 'Đã thuộc'
                                                              : 'Đang học',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                notebookItem
                                                                    .isMastered
                                                                ? const Color(
                                                                    0xFF16A34A,
                                                                  )
                                                                : const Color(
                                                                    0xFF9333EA,
                                                                  ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  if (flashcard
                                                      .audioUrl
                                                      .isNotEmpty)
                                                    Material(
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF334155,
                                                            )
                                                          : const Color(
                                                              0xFFF8FAFC,
                                                            ),
                                                      shape:
                                                          const CircleBorder(),
                                                      child: IconButton(
                                                        onPressed: () =>
                                                            _playAudio(
                                                              flashcard
                                                                  .audioUrl,
                                                            ),
                                                        icon: Icon(
                                                          _playingUrl ==
                                                                      flashcard
                                                                          .audioUrl &&
                                                                  _audioPlayer
                                                                      .playing
                                                              ? Icons
                                                                    .stop_circle_rounded
                                                              : Icons
                                                                    .volume_up_rounded,
                                                          size: 20,
                                                          color:
                                                              leadingBadgeIcon,
                                                        ),
                                                        constraints:
                                                            const BoxConstraints.tightFor(
                                                              width: 40,
                                                              height: 40,
                                                            ),
                                                        padding:
                                                            EdgeInsets.zero,
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
                                ),
                              ),
                            ),
                          ),
                        ),
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
