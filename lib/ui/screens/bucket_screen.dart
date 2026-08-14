import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../data/database/word_dao.dart';
import '../../data/models/word_model.dart';
import '../../data/services/clipboard_capture_service.dart';
import '../../providers/word_provider.dart';
import '../widgets/word_details.dart';

class BucketScreen extends ConsumerStatefulWidget {
  const BucketScreen({super.key});

  @override
  ConsumerState<BucketScreen> createState() => BucketScreenState();
}

class BucketScreenState extends ConsumerState<BucketScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _suggestionTimer;
  int _suggestionGeneration = 0;
  List<String> _suggestions = const [];
  WordModel? _selectedWord;

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _suggestionTimer?.cancel();
    final request = ++_suggestionGeneration;
    if (value.trim().length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _suggestionTimer = Timer(const Duration(milliseconds: 300), () async {
      final suggestions = await ref
          .read(wordSuggestionServiceProvider)
          .suggest(value);
      if (!mounted ||
          request != _suggestionGeneration ||
          value != _searchController.text) {
        return;
      }
      setState(() => _suggestions = suggestions);
    });
  }

  void _lookUp([String? value]) {
    final word = value ?? _searchController.text;
    _suggestionTimer?.cancel();
    _suggestionGeneration++;
    _searchController.text = word;
    _searchController.selection = TextSelection.collapsed(offset: word.length);
    _focusNode.unfocus();
    setState(() {
      _suggestions = const [];
      _selectedWord = null;
    });
    ref.read(lookupProvider.notifier).lookUp(word);
  }

  Future<void> _save() async {
    final saved = await ref.read(lookupProvider.notifier).save();
    if (!mounted || saved == null) return;
    _searchController.clear();
    setState(() {
      _suggestions = const [];
      _selectedWord = saved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${saved.word}” saved to your bucket.')),
    );
  }

  Future<void> defineClipboard() async {
    try {
      final word = await const ClipboardCaptureService().readWord();
      if (!mounted) return;
      _lookUp(word);
    } on ClipboardCaptureException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WordBucket could not read the clipboard.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(savedWordsProvider);
    final lookup = ref.watch(lookupProvider);
    final previewWord = lookup.result ?? _selectedWord;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _lookUp,
                    decoration: InputDecoration(
                      hintText: 'Search or define a word…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Define word',
                        onPressed: lookup.isLoading ? null : _lookUp,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final suggestion in _suggestions)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.auto_awesome, size: 17),
                              title: Text(suggestion),
                              onTap: () => _lookUp(suggestion),
                            ),
                        ],
                      ),
                    ),
                  if (lookup.isLoading) ...[
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lookup.isRetrying
                          ? 'Rebucketifying after a short pause…'
                          : 'Bucketifying your word…',
                    ),
                  ],
                  if (lookup.error case final error?) ...[
                    const SizedBox(height: 14),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Your words',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      words.when(
                        data: (items) => Text('${items.length} saved'),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: words.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text('Could not open your bucket: $error'),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'Search above to save your first word.',
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              selected: _selectedWord?.word == item.word,
                              leading: const Icon(
                                Icons.bookmark_outline_rounded,
                              ),
                              title: Text(item.word),
                              subtitle: Text(
                                item.definition,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                ref.read(lookupProvider.notifier).clear();
                                setState(() => _selectedWord = item.toModel());
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (wide) ...[
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: WordDetails(
              word: previewWord,
              showSave: lookup.result != null && !lookup.existing,
              alreadySaved:
                  lookup.existing ||
                  (_selectedWord != null && lookup.result == null),
              onSave: _save,
            ),
          ),
        ],
      ],
    );
  }
}
