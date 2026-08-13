import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/database/word_dao.dart';
import '../data/models/word_model.dart';
import '../data/services/dictionary_service.dart';
import '../data/services/word_suggestion_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final savedWordsProvider = StreamProvider<List<SavedWord>>(
  (ref) => ref.watch(databaseProvider).watchAllWords(),
);

final wordSuggestionServiceProvider = Provider(
  (ref) => WordSuggestionService(),
);

final lookupProvider = StateNotifierProvider<LookupNotifier, LookupState>((
  ref,
) {
  return LookupNotifier(DictionaryService(), ref.watch(databaseProvider));
});

class LookupState {
  const LookupState({
    this.isLoading = false,
    this.isRetrying = false,
    this.result,
    this.error,
    this.existing = false,
  });

  final bool isLoading;
  final bool isRetrying;
  final WordModel? result;
  final String? error;
  final bool existing;
}

class LookupNotifier extends StateNotifier<LookupState> {
  LookupNotifier(this._dictionary, this._database) : super(const LookupState());

  final DictionaryService _dictionary;
  final AppDatabase _database;
  int _generation = 0;

  Future<void> lookUp(String text) async {
    final word = text.trim().toLowerCase();
    final request = ++_generation;
    if (word.isEmpty) {
      state = const LookupState(error: 'Enter a word to define.');
      return;
    }
    state = const LookupState(isLoading: true);

    final saved = await _database.getWord(word);
    if (request != _generation) return;
    if (saved != null) {
      state = LookupState(result: saved.toModel(), existing: true);
      return;
    }

    DictionaryException? primaryError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await _dictionary.define(word);
        if (request == _generation) state = LookupState(result: result);
        return;
      } on DictionaryException catch (error) {
        primaryError = error;
        if (!error.isRetryable || attempt == 1) break;
        if (request == _generation) {
          state = const LookupState(isLoading: true, isRetrying: true);
        }
        await Future<void>.delayed(const Duration(seconds: 5));
        if (request != _generation) return;
      }
    }

    try {
      final result = await _dictionary.defineFallback(word);
      if (request == _generation) state = LookupState(result: result);
    } on DictionaryException catch (fallbackError) {
      if (request == _generation) {
        state = LookupState(
          error: primaryError?.message ?? fallbackError.message,
        );
      }
    }
  }

  Future<WordModel?> save() async {
    final result = state.result;
    if (result == null || state.existing) return null;
    await _database.saveWord(result);
    state = LookupState(result: result, existing: true);
    return result;
  }

  void clear() {
    _generation++;
    state = const LookupState();
  }
}
