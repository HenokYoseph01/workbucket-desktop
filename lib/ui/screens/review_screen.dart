import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/database/word_dao.dart';
import '../../providers/word_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.words, super.key});

  final List<SavedWord> words;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _index = 0;
  bool _revealed = false;
  bool _saving = false;

  Future<void> _answer(bool remembered) async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref
        .read(databaseProvider)
        .recordReviewAttempt(widget.words[_index], remembered: remembered);
    if (!mounted) return;
    if (_index == widget.words.length - 1) {
      ref.invalidate(dueWordsProvider);
      ref.invalidate(savedWordsProvider);
      ref.invalidate(reviewStatisticsProvider);
      Navigator.of(context).pop('Review complete. Your schedule is updated.');
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_index];
    final progress = (_index + 1) / widget.words.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Review'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('WORD ${_index + 1} OF ${widget.words.length}'),
                    const Spacer(),
                    Text('${(progress * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 28),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            word.word,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (word.phonetic case final phonetic?) ...[
                            const SizedBox(height: 8),
                            Text(phonetic),
                          ],
                          const SizedBox(height: 32),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: _revealed
                                ? Column(
                                    key: const ValueKey('definition'),
                                    children: [
                                      Chip(label: Text(word.partOfSpeech)),
                                      const SizedBox(height: 18),
                                      Text(
                                        word.definition,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Do you remember what this word means?',
                                    key: const ValueKey('prompt'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (!_revealed)
                  FilledButton.icon(
                    onPressed: () => setState(() => _revealed = true),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Reveal definition'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : () => _answer(false),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Needs practice'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : () => _answer(true),
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: const Text('Remembered'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
