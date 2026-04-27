import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result/result.dart';
import '../../widgets/assignment/essay_form_widget.dart';
import '../../widgets/assignment/essay_result_widget.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class EssayScreen extends ConsumerStatefulWidget {
  const EssayScreen({required this.essayId, super.key});
  final String essayId;

  @override
  ConsumerState<EssayScreen> createState() => _EssayScreenState();
}

class _EssayScreenState extends ConsumerState<EssayScreen> {
  bool _submitting = false;

  Future<void> _submit(String content) async {
    if (content.trim().isEmpty) return;
    setState(() => _submitting = true);
    final result = await ref
        .read(assignmentFeatureViewModelProvider)
        .submitEssay(essayId: widget.essayId, content: content.trim());
    setState(() => _submitting = false);

    if (!mounted) return;

    final msg = switch (result) {
      Success() => 'Nộp bài thành công',
      Failure(:final error) => error.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    if (result is Success) {
      // Refresh status after successful submission
      ref.invalidate(essaySubmissionStatusProvider(widget.essayId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncEssay = ref.watch(essayDetailProvider(widget.essayId));
    final asyncStatus = ref.watch(
      essaySubmissionStatusProvider(widget.essayId),
    );

    return CatalunyaScaffold(
      appBar: AppBar(
        title: const Text('Bài tự luận'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: asyncEssay.when(
        data: (essay) {
          return asyncStatus.when(
            data: (submission) {
              if (submission != null) {
                return EssayResultWidget(
                  submission: submission,
                  instruction: essay.instruction,
                  audioUrl: essay.audioUrl,
                  imageUrl: essay.imageUrl,
                  onBack: () => Navigator.of(context).pop(),
                );
              }

              return EssayFormWidget(
                instruction: essay.instruction,
                audioUrl: essay.audioUrl,
                imageUrl: essay.imageUrl,
                isSubmitting: _submitting,
                onOpenMenu: () {},
                onSubmit: _submit,
              );
            },
            loading: () => const LoadingStateView(),
            error: (error, _) => ErrorStateView(message: '$error'),
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}
