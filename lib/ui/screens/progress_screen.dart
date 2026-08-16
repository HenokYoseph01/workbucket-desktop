import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/word_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(reviewStatisticsProvider);
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(reviewStatisticsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Reload progress'),
        ),
      ),
      data: (data) => SingleChildScrollView(
        child: Column(
          children: [
            _Hero(data),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                _Metric(Icons.bookmarks, '${data.totalWords}', 'Saved words'),
                _Metric(Icons.fact_check, '${data.totalReviews}', 'Reviews'),
                _Metric(Icons.schedule, '${data.dueWords}', 'Due now'),
                _Metric(
                  Icons.local_fire_department,
                  '${data.longestStreak}',
                  'Best streak',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Activity(data)),
                const SizedBox(width: 16),
                Expanded(child: _Mastery(data)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Ranked('Strongest words', data.strongest)),
                const SizedBox(width: 16),
                Expanded(child: _Ranked('Needs practice', data.weakest)),
              ],
            ),
            const SizedBox(height: 16),
            _Upcoming(data),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero(this.data);
  final ReviewStatistics data;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(
      color: c.primary,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: c.tertiaryContainer,
              size: 42,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.currentStreak} day review streak',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: c.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'A quiet record of the words you are making your own.',
                    style: TextStyle(color: c.onPrimary.withValues(alpha: .72)),
                  ),
                ],
              ),
            ),
            Text(
              '${(data.recallRate * 100).round()}%\nretained',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Activity extends StatelessWidget {
  const _Activity(this.data);
  final ReviewStatistics data;
  @override
  Widget build(BuildContext context) {
    final max = data.activity.fold<int>(
      1,
      (m, d) => d.reviews > m ? d.reviews : m,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 7 days', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in data.activity)
                    Expanded(
                      child: Column(
                        children: [
                          Text('${d.reviews}'),
                          const SizedBox(height: 4),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) => Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 20,
                                  height:
                                      constraints.maxHeight *
                                      (d.reviews == 0
                                          ? 0.08
                                          : 0.2 + (0.8 * d.reviews / max)),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.date.weekday -
                                1],
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

class _Mastery extends StatelessWidget {
  const _Mastery(this.data);
  final ReviewStatistics data;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Word mastery', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _row('New', data.count(MasteryLevel.newWord)),
          _row('Learning', data.count(MasteryLevel.learning)),
          _row('Strong', data.count(MasteryLevel.strong)),
          _row('Needs practice', data.count(MasteryLevel.needsPractice)),
        ],
      ),
    ),
  );
  Widget _row(String l, int n) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(l)),
        Text('$n', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _Ranked extends StatelessWidget {
  const _Ranked(this.title, this.words);
  final String title;
  final List<WordMastery> words;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (words.isEmpty)
            const Text('Complete more reviews to reveal this list.')
          else
            for (final w in words)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(w.word.word),
                trailing: Text('${(w.recallRate * 100).round()}%'),
              ),
        ],
      ),
    ),
  );
}

class _Upcoming extends StatelessWidget {
  const _Upcoming(this.data);
  final ReviewStatistics data;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coming up', style: Theme.of(context).textTheme.titleLarge),
          if (data.upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('You are all caught up.'),
            )
          else
            for (final w in data.upcoming)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book),
                title: Text(w.word),
                trailing: Text(_formatDate(w.nextReviewAt!)),
              ),
        ],
      ),
    ),
  );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(date.year, date.month, date.day);
    final difference = reviewDay.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
