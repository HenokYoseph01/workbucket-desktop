import 'package:flutter/material.dart';

import '../../data/models/word_model.dart';

class WordDetails extends StatelessWidget {
  const WordDetails({
    required this.word,
    this.showSave = false,
    this.alreadySaved = false,
    this.onSave,
    super.key,
  });

  final WordModel? word;
  final bool showSave;
  final bool alreadySaved;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final item = word;
    if (item == null) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text('Search for or select a word to see its definition.'),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.word,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (alreadySaved)
                  const Chip(
                    avatar: Icon(Icons.check_rounded, size: 16),
                    label: Text('In your bucket'),
                  ),
              ],
            ),
            if (item.phonetic case final phonetic?) ...[
              const SizedBox(height: 6),
              Text(phonetic),
            ],
            const SizedBox(height: 18),
            Chip(label: Text(item.partOfSpeech)),
            const SizedBox(height: 20),
            Text(
              item.definition,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (item.exampleSentence case final example?) ...[
              const SizedBox(height: 20),
              Text(
                '“$example”',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            if (showSave) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Save to my bucket'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
