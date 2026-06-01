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
      final String outputPath = kIsWeb
          ? 'pronunciation.wav'
          : '${Directory.systemTemp.path}${Platform.pathSeparator}pronunciation_${DateTime.now().millisecondsSinceEpoch}.wav';

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
          ref.invalidate(pronunciationListProvider(widget.moduleId));
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

          final canGoPrevious = safeIndex > 0;
          final isLastCard = safeIndex == _localItems.length - 1;

          return Column(
            children: [
              // Progress Header (Fixed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (safeIndex + 1) / _localItems.length,
                          backgroundColor: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${safeIndex + 1}/${_localItems.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Main Card
                      CatalunyaCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Score Banner + Phân tích âm tiết
                            if (_assessmentResult != null) ...[
                              _PronunciationDetailedFeedbackWidget(
                                result: _assessmentResult!,
                              ),
                              const SizedBox(height: 24),
                            ] else if (current.progress.hasPracticed) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _scoreColor(
                                        current.progress.bestScore,
                                      ).withValues(alpha: 0.1),
                                      _scoreColor(
                                        current.progress.bestScore,
                                      ).withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _scoreColor(
                                      current.progress.bestScore,
                                    ).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${current.progress.bestScore.toStringAsFixed(1)} điểm',
                                      style: TextStyle(
                                        color: _scoreColor(
                                          current.progress.bestScore,
                                        ),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Điểm tốt nhất: ${current.progress.bestScore.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: _scoreColor(
                                          current.progress.bestScore,
                                        ).withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Word & Meaning
                            Text(
                              current.word,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.color,
                                letterSpacing: -0.5,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (current.phonetic.isNotEmpty)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).cardColor.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '/${current.phonetic}/',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              current.meaning,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.color
                                    ?.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 32),

                            Text(
                              _isRecording
                                  ? 'Đang lắng nghe...'
                                  : 'Nhấn vào mic để phát âm',
                              style: TextStyle(
                                color: _isRecording
                                    ? Colors.red
                                    : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Mic Button
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
                                  if (_isRecording)
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 1.0, end: 1.4),
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.easeInOutSine,
                                      builder: (context, value, child) {
                                        return Container(
                                          width: 72 * value,
                                          height: 72 * value,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: _isRecording
                                            ? const [
                                                Color(0xFFEF4444),
                                                Color(0xFFB91C1C),
                                              ]
                                            : const [
                                                Color(0xFF3B82F6),
                                                Color(0xFF1D4ED8),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (_isRecording
                                                      ? Colors.red
                                                      : Colors.blue)
                                                  .withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: _isProcessing
                                        ? const Padding(
                                            padding: EdgeInsets.all(20),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : Icon(
                                            _isRecording
                                                ? Icons.stop_rounded
                                                : Icons.mic_rounded,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Score Chips
                            if (_assessmentResult != null)
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

                            const SizedBox(height: 20),

                            // Bottom Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    onPressed: canGoPrevious
                                        ? _onPrevious
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.blueGrey,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Từ trước',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    onPressed: _playRecordedAudio,
                                    icon: const Icon(
                                      Icons.volume_up_rounded,
                                      color: Color(0xFF10B981),
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Nghe lại',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _playReferenceAudio(current.audioUrl),
                                    icon: const Icon(
                                      Icons.volume_up_rounded,
                                      color: Color(0xFF10B981),
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Nghe chuẩn',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => _onNext(_localItems.length),
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  isLastCard ? 'Hoàn thành' : 'Từ tiếp theo',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: summaryAsync.when(
          data: (summary) {
            final avgScore = summary.averageScore;
            final scoreColor = avgScore >= 85
                ? const Color(0xFF10B981)
                : (avgScore >= 70
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444));

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Trophy Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFEDD5),
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 64,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kết quả luyện tập',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn đã hoàn thành bài luyện phát âm!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Score Circular View
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              avgScore.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: scoreColor,
                              ),
                            ),
                            const Text(
                              'ĐIỂM TRUNG BÌNH',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.blueGrey,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                        Column(
                          children: [
                            Text(
                              summary.grade.isEmpty ? '-' : summary.grade,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: scoreColor,
                              ),
                            ),
                            const Text(
                              'XẾP LOẠI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.blueGrey,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  Row(
                    children: [
                      _CompactStatItem(
                        icon: Icons.menu_book_rounded,
                        label: 'Đã luyện',
                        value:
                            '${summary.totalPracticed}/${summary.totalFlashcards}',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _CompactStatItem(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Đã thuộc',
                        value: '${summary.masteredCount}',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Feedback Message
                  if (summary.message.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              summary.message,
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          onPressed: onPracticeAgain,
                          child: const Text(
                            'Luyện lại',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: onBack,
                          child: const Text(
                            'Quay lại',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingStateView(),
          error: (error, _) => ErrorStateView(message: '$error'),
        ),
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PronunciationDetailedFeedbackWidget extends StatelessWidget {
  const _PronunciationDetailedFeedbackWidget({required this.result});

  final PronunciationAssessmentResultModel result;

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981); // Emerald
    if (score >= 60) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getScoreColor(result.accuracyScore);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${result.accuracyScore.toStringAsFixed(1)} điểm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (result.feedback.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌟🌟 ', style: TextStyle(fontSize: 12)),
                    Flexible(
                      child: Text(
                        result.feedback,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Phân tích âm tiết',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        result.words.isNotEmpty ? result.words.first.word : '',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        result.accuracyScore >= 80
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: result.words.expand((word) => word.phonemes).map((
                      p,
                    ) {
                      Color pColor = _getScoreColor(p.accuracyScore);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: pColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          p.phoneme,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: pColor,
                          ),
                        ),
                      );
                    }).toList(),
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
