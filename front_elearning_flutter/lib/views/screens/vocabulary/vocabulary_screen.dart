import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../../models/flashcard/flashcard_models.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_reveal.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';

final _dueReviewCardsProvider =
    FutureProvider.autoDispose<List<FlashcardModel>>((ref) async {
      final result = await ref
          .read(flashcardFeatureViewModelProvider)
          .dueReviewCards();
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDueCards = ref.watch(_dueReviewCardsProvider);
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Sổ tay từ vựng')),
      body: asyncDueCards.when(
        data: (cards) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              CatalunyaReveal(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220EA5E9),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Từ cần ôn hôm nay',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${cards.length}',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0A84FF),
                        ),
                        onPressed: cards.isEmpty
                            ? null
                            : () => context.push(RoutePaths.flashcardReview),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Bắt đầu ôn tập'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Danh sách cần ôn',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (cards.isEmpty)
                const CatalunyaCard(
                  child: EmptyStateView(
                    message: 'Không có từ nào cần ôn tập hôm nay',
                    icon: Icons.check_circle_outline,
                  ),
                )
              else
                ...cards.take(12).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  return CatalunyaReveal(
                    delay: Duration(milliseconds: 60 * index),
                    child: CatalunyaCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F4FF),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(card.term),
                        subtitle: Text(
                          card.definition.isEmpty
                              ? 'Nhấn ôn tập để xem nghĩa'
                              : card.definition,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(RoutePaths.flashcardReview),
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
}
