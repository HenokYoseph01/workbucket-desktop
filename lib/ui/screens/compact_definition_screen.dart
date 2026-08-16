import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/word_provider.dart';

class CompactDefinitionScreen extends ConsumerWidget {
  const CompactDefinitionScreen({
    required this.onOpenApp,
    required this.onReturnToReading,
    super.key,
  });

  final VoidCallback onOpenApp;
  final VoidCallback onReturnToReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(lookupProvider);
    final word = lookup.result;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: desktopGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_library_rounded, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'WordBucket',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Return to reading',
                    onPressed: onReturnToReading,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 26),
              if (lookup.isLoading) ...[
                const Spacer(),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    lookup.isRetrying
                        ? 'Rebucketifying after a short pause…'
                        : 'Bucketifying your word…',
                  ),
                ),
                const Spacer(),
              ] else if (lookup.error case final error?) ...[
                const Spacer(),
                Center(child: Text(error, textAlign: TextAlign.center)),
                const Spacer(),
              ] else if (word != null) ...[
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (word.phonetic case final phonetic?) Text(phonetic),
                const SizedBox(height: 12),
                Chip(label: Text(word.partOfSpeech)),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      word.definition,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                _SaveStatusButton(
                  key: ValueKey(word.word),
                  alreadySaved: lookup.existing,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onOpenApp,
                    child: const Text('Open WordBucket'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onReturnToReading,
                    child: const Text('Return to reading'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveStatusButton extends ConsumerStatefulWidget {
  const _SaveStatusButton({required this.alreadySaved, super.key});

  final bool alreadySaved;

  @override
  ConsumerState<_SaveStatusButton> createState() => _SaveStatusButtonState();
}

class _SaveStatusButtonState extends ConsumerState<_SaveStatusButton> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saving || _saved || widget.alreadySaved) return;
    setState(() => _saving = true);
    final saved = await ref.read(lookupProvider.notifier).save();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = saved != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complete = _saved || widget.alreadySaved;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: FilledButton.icon(
        key: ValueKey((complete, _saving)),
        onPressed: complete || _saving ? null : _save,
        style: complete
            ? FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3D7A52),
                disabledBackgroundColor: const Color(0xFF3D7A52),
                disabledForegroundColor: Colors.white,
              )
            : null,
        icon: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(complete ? Icons.check_rounded : Icons.bookmark_add_rounded),
        label: Text(
          _saving
              ? 'Saving…'
              : complete
              ? (widget.alreadySaved && !_saved
                    ? 'Already in your bucket'
                    : 'Saved to bucket')
              : 'Save to bucket',
        ),
      ),
    );
  }
}
