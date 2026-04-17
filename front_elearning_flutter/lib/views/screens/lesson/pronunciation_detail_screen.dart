import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../../app/providers.dart';
import '../../../core/result/result.dart';
import '../../../models/learning/pronunciation_models.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class PronunciationDetailScreen extends ConsumerStatefulWidget {
  const PronunciationDetailScreen({
    required this.moduleId,
    this.startIndex = 0,
    super.key,
  });

  final String moduleId;
  final int startIndex;

  @override
  ConsumerState<PronunciationDetailScreen> createState() =>
      _PronunciationDetailScreenState();
}

class _PronunciationDetailScreenState
    extends ConsumerState<PronunciationDetailScreen> {
  late final AudioPlayer _audioPlayer;
  late final AudioRecorder _recorder;

  int _currentIndex = 0;
  bool _showSummary = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _playingSource = '';
  String? _recordedPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  Timer? _micPulseTimer;
  bool _micPulse = false;
  PronunciationAssessmentResultModel? _assessmentResult;
  List<PronunciationItemModel> _localItems = const [];
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _recorder = AudioRecorder();
    _currentIndex = widget.startIndex;

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingSource = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _micPulseTimer?.cancel();
    _playerStateSub?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _stopPlayback() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      if (!mounted) return;
      setState(() => _playingSource = '');
    } catch (_) {}
  }

  Future<void> _playReferenceAudio(String audioUrl) async {
    try {
      if (_audioPlayer.playing && _playingSource == 'reference:$audioUrl') {
        await _stopPlayback();
        return;
      }

      await _stopPlayback();
      _playingSource = 'reference:$audioUrl';
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

  Future<void> _playRecordedAudio() async {
    final path = _recordedPath;
    if (path == null || path.isEmpty) return;

    try {
      if (_audioPlayer.playing && _playingSource == 'recorded') {
        await _stopPlayback();
        return;
      }

      await _stopPlayback();
      _playingSource = 'recorded';
      if (kIsWeb) {
        await _audioPlayer.setUrl(path);
      } else {
        await _audioPlayer.setFilePath(path);
      }
      await _audioPlayer.play();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát lại bản ghi âm')),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isProcessing) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần quyền micro để ghi âm phát âm')),
      );
      return;
    }

    await _stopPlayback();
    _assessmentResult = null;

    try {
      String outputPath = '';
      if (!kIsWeb) {
        outputPath = '${Directory.systemTemp.path}${Platform.pathSeparator}pronunciation_${DateTime.now().millisecondsSinceEpoch}.wav';
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: outputPath,
      );

      _recordingTimer?.cancel();
      _recordingDuration = Duration.zero;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecording) return;
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + 1,
          );
        });
      });

      _micPulseTimer?.cancel();
      _micPulse = true;
      _micPulseTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
        if (!mounted || !_isRecording) return;
        setState(() {
          _micPulse = !_micPulse;
        });
      });

      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể bắt đầu ghi âm')));
    }
  }

  Future<void> _stopRecordingAndAssess(PronunciationItemModel current) async {
    if (!_isRecording || _isProcessing) return;

    try {
      final path = await _recorder.stop();
      _recordingTimer?.cancel();
      _micPulseTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _micPulse = false;
      });

      if (path == null || path.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được file ghi âm')),
        );
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .assessPronunciation(
            flashCardId: current.flashCardId,
            filePath: path,
            fileName: 'pronunciation_$now.wav',
            durationInSeconds: _recordingDuration.inMilliseconds / 1000,
          );

      if (!mounted) return;

      switch (result) {
        case Success(:final value):
          final oldProgress = current.progress;
          final best = value.pronunciationScore > oldProgress.bestScore
              ? value.pronunciationScore
              : oldProgress.bestScore;
          final attempts = oldProgress.totalAttempts + 1;
          final mastered = oldProgress.isMastered || best >= 90;

          final updated = current.copyWith(
            progress: oldProgress.copyWith(
              totalAttempts: attempts,
              bestScore: best,
              lastPronunciationScore: value.pronunciationScore,
              isMastered: mastered,
              status: mastered ? 'Mastered' : 'Practicing',
            ),
          );

          final list = [..._localItems];
          list[_currentIndex] = updated;

          setState(() {
            _recordedPath = path;
            _assessmentResult = value;
            _localItems = list;
            _isProcessing = false;
          });

          ref.invalidate(pronunciationSummaryProvider(widget.moduleId));
        case Failure(:final error):
          setState(() {
            _recordedPath = path;
            _isProcessing = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      _recordingTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xử lý ghi âm phát âm')),
      );
    }
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Color _scoreColor(double score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _resetPracticeStateForIndex() {
    _assessmentResult = null;
    _recordedPath = null;
    _playingSource = '';
    _recordingDuration = Duration.zero;
    _isRecording = false;
    _isProcessing = false;
    _micPulse = false;
    _recordingTimer?.cancel();
    _micPulseTimer?.cancel();
  }

  void _onNext(int total) {
    if (_currentIndex < total - 1) {
      _stopPlayback();
      setState(() {
        _currentIndex += 1;
        _resetPracticeStateForIndex();
      });
      return;
    }

    _stopPlayback();
    setState(() {
      _showSummary = true;
    });
  }

  void _onPrevious() {
    if (_currentIndex == 0) return;

    _stopPlayback();
    setState(() {
      _currentIndex -= 1;
      _resetPracticeStateForIndex();
    });
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
        data: (fetchedList) {
          if (fetchedList.isEmpty) {
            return const ErrorStateView(message: 'Không có dữ liệu phát âm');
          }

          if (_localItems.length != fetchedList.length) {
            _localItems = [...fetchedList];
          }

          final safeIndex = _currentIndex.clamp(0, _localItems.length - 1);
          final current = _localItems[safeIndex];

          if (_showSummary) {
            return _PronunciationSummaryView(
              summaryAsync: asyncSummary,
              onPracticeAgain: () => setState(() {
                _currentIndex = 0;
                _showSummary = false;
                _resetPracticeStateForIndex();
              }),
              onBack: () => Navigator.of(context).maybePop(),
            );
          }

          final score =
              _assessmentResult?.pronunciationScore ??
              (current.progress.hasPracticed ? current.progress.bestScore : 0);
          final showScore =
              _assessmentResult != null || current.progress.hasPracticed;
          final feedback = _assessmentResult?.feedback.isNotEmpty == true
              ? _assessmentResult!.feedback
              : (current.progress.hasPracticed
                    ? 'Điểm tốt nhất: ${current.progress.bestScore.toStringAsFixed(1)}'
                    : 'Chưa tính điểm');

          final canGoPrevious = safeIndex > 0;
          final isLastCard = safeIndex == _localItems.length - 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (safeIndex + 1) / _localItems.length,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${safeIndex + 1}/${_localItems.length}'),
                ],
              ),
              const SizedBox(height: 14),
              CatalunyaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: showScore
                            ? _scoreColor(score).withValues(alpha: 0.12)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            showScore
                                ? '${score.toStringAsFixed(1)} điểm'
                                : 'Chưa tính điểm',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: showScore
                                      ? _scoreColor(score)
                                      : Colors.black54,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            feedback,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      current.word,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (current.phonetic.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '/${current.phonetic}/',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    if (current.meaning.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        current.meaning,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      _isRecording
                          ? 'Đang ghi âm ${_formatDuration(_recordingDuration)}'
                          : 'Nhấn vào mic để phát âm',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    if (_isRecording) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _micPulse
                                  ? const Color(0xFFEF4444)
                                  : const Color(0x77EF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recording...',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _isProcessing
                          ? null
                          : () {
                              if (_isRecording) {
                                _stopRecordingAndAssess(current);
                              } else {
                                _startRecording();
                              }
                            },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 380),
                            width: _isRecording ? (_micPulse ? 124 : 112) : 0,
                            height: _isRecording ? (_micPulse ? 124 : 112) : 0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x22EF4444),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isRecording
                                    ? const [
                                        Color(0xFFEF4444),
                                        Color(0xFFDC2626),
                                      ]
                                    : const [
                                        Color(0xFF2563EB),
                                        Color(0xFF1D4ED8),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_isRecording
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF1D4ED8))
                                          .withValues(alpha: 0.35),
                                  blurRadius: _isRecording ? 18 : 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isRecording
                                          ? Icons.stop_rounded
                                          : Icons.mic_rounded,
                                      size: 44,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_assessmentResult != null) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _ScoreChip(
                            label: 'Accuracy',
                            value: _assessmentResult!.accuracyScore,
                          ),
                          _ScoreChip(
                            label: 'Fluency',
                            value: _assessmentResult!.fluencyScore,
                          ),
                          _ScoreChip(
                            label: 'Completeness',
                            value: _assessmentResult!.completenessScore,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (canGoPrevious)
                          OutlinedButton.icon(
                            onPressed: _onPrevious,
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: const Text('Từ trước'),
                          ),
                        if (_recordedPath != null)
                          OutlinedButton.icon(
                            onPressed: _playRecordedAudio,
                            icon: Icon(
                              _playingSource == 'recorded' &&
                                      _audioPlayer.playing
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_rounded,
                            ),
                            label: Text(
                              _playingSource == 'recorded' &&
                                      _audioPlayer.playing
                                  ? 'Dừng'
                                  : 'Nghe lại',
                            ),
                          ),
                        if (_assessmentResult != null &&
                            current.audioUrl.isNotEmpty)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              side: const BorderSide(color: Color(0xFF10B981)),
                            ),
                            onPressed: () =>
                                _playReferenceAudio(current.audioUrl),
                            icon: Icon(
                              _playingSource ==
                                          'reference:${current.audioUrl}' &&
                                      _audioPlayer.playing
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_rounded,
                            ),
                            label: Text(
                              _playingSource ==
                                          'reference:${current.audioUrl}' &&
                                      _audioPlayer.playing
                                  ? 'Dừng'
                                  : 'Nghe chuẩn',
                            ),
                          ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            elevation: 6,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _onNext(_localItems.length),
                          icon: Icon(
                            isLastCard
                                ? Icons.check_circle_outline_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          label: Text(
                            isLastCard ? 'Hoàn thành' : 'Từ tiếp theo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}

class _PronunciationSummaryView extends StatelessWidget {
  const _PronunciationSummaryView({
    required this.summaryAsync,
    required this.onPracticeAgain,
    required this.onBack,
  });

  final AsyncValue summaryAsync;
  final VoidCallback onPracticeAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CatalunyaCard(
          child: summaryAsync.when(
            data: (summary) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 64,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hoàn thành luyện phát âm',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatChip(
                      label: 'Đã luyện',
                      value:
                          '${summary.totalPracticed}/${summary.totalFlashcards}',
                    ),
                    _StatChip(
                      label: 'Đã thuộc',
                      value: '${summary.masteredCount}',
                    ),
                    _StatChip(
                      label: 'Điểm TB',
                      value: summary.averageScore.toStringAsFixed(1),
                    ),
                    _StatChip(
                      label: 'Xếp loại',
                      value: summary.grade.isEmpty ? '-' : summary.grade,
                    ),
                  ],
                ),
                if (summary.message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    summary.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onPracticeAgain,
                        child: const Text('Luyện lại'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onBack,
                        child: const Text('Quay lại'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const LoadingStateView(),
            error: (error, _) => ErrorStateView(message: '$error'),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final scoreColor = value >= 85
        ? const Color(0xFF10B981)
        : (value >= 65 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}',
        style: TextStyle(
          color: scoreColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
