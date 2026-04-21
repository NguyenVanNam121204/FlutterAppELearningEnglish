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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroButtonBg = isDark ? const Color(0xFFE2ECFF) : Colors.white;
    final heroButtonFg = isDark
        ? const Color(0xFF1E3A8A)
        : const Color(0xFF0A84FF);
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Sổ tay từ vựng')),
      body: asyncDueCards.when(
        data: (cards) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              CatalunyaReveal(
                child: _ReviewHeroCard(
                  total: cards.length,
                  isDark: isDark,
                  heroButtonBg: heroButtonBg,
                  heroButtonFg: heroButtonFg,
                  onStartReview: cards.isEmpty
                      ? null
                      : () => context.push(RoutePaths.flashcardReview),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Danh sách cần ôn',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF223449)
                          : const Color(0xFFE8F4FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${cards.length} từ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    child: _ReviewWordCard(
                      index: index,
                      card: card,
                      isDark: isDark,
                      onTap: () => context.push(RoutePaths.flashcardReview),
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

class _ReviewHeroCard extends StatelessWidget {
  const _ReviewHeroCard({
    required this.total,
    required this.isDark,
    required this.heroButtonBg,
    required this.heroButtonFg,
    required this.onStartReview,
  });

  final int total;
  final bool isDark;
  final Color heroButtonBg;
  final Color heroButtonFg;
  final VoidCallback? onStartReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0D6AA8), Color(0xFF1CA36B)]
              : const [Color(0xFF0EA5E9), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7))
                .withValues(alpha: isDark ? 0.20 : 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Từ cần ôn hôm nay',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$total',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: heroButtonBg,
              foregroundColor: heroButtonFg,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: onStartReview,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Bắt đầu ôn tập'),
          ),
        ],
      ),
    );
  }
}

class _ReviewWordCard extends StatelessWidget {
  const _ReviewWordCard({
    required this.index,
    required this.card,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final FlashcardModel card;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeBg = isDark ? const Color(0xFF223449) : const Color(0xFFE8F4FF);
    final badgeFg = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8);
    final subtitle = card.definition.isEmpty
        ? 'Nhấn ôn tập để xem nghĩa'
        : card.definition;

    return CatalunyaCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeBg,
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badgeFg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.term,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 40 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 30,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
