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

final dueWordsProvider = FutureProvider<List<SavedWord>>(
  (ref) => ref.watch(databaseProvider).getWordsDueForReview(),
);

enum MasteryLevel { newWord, learning, strong, needsPractice }

class WordMastery {
  const WordMastery(this.word, this.attempts, this.remembered, this.level);
  final SavedWord word;
  final int attempts;
  final int remembered;
  final MasteryLevel level;
  double get recallRate => attempts == 0 ? 0 : remembered / attempts;
}

class DailyActivity {
  const DailyActivity(this.date, this.reviews, this.remembered);
  final DateTime date;
  final int reviews;
  final int remembered;
}

class ReviewStatistics {
  const ReviewStatistics({
    required this.totalWords,
    required this.dueWords,
    required this.totalReviews,
    required this.rememberedReviews,
    required this.currentStreak,
    required this.longestStreak,
    required this.mastery,
    required this.activity,
    required this.upcoming,
  });
  final int totalWords;
  final int dueWords;
  final int totalReviews;
  final int rememberedReviews;
  final int currentStreak;
  final int longestStreak;
  final List<WordMastery> mastery;
  final List<DailyActivity> activity;
  final List<SavedWord> upcoming;
  double get recallRate =>
      totalReviews == 0 ? 0 : rememberedReviews / totalReviews;
  int count(MasteryLevel level) =>
      mastery.where((item) => item.level == level).length;
  List<WordMastery> get strongest =>
      (mastery.where((item) => item.level == MasteryLevel.strong).toList()
            ..sort((a, b) => b.recallRate.compareTo(a.recallRate)))
          .take(5)
          .toList();
  List<WordMastery> get weakest =>
      (mastery
              .where((item) => item.level == MasteryLevel.needsPractice)
              .toList()
            ..sort((a, b) => a.recallRate.compareTo(b.recallRate)))
          .take(5)
          .toList();
}

final reviewStatisticsProvider = FutureProvider<ReviewStatistics>((ref) async {
  final database = ref.watch(databaseProvider);
  final words = await database.getAllWords();
  final due = await database.getWordsDueForReview();
  final history = await database.getReviewHistory();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final mastery = words.map((word) {
    final attempts = history.where((item) => item.word == word.word).toList();
    final remembered = attempts.where((item) => item.remembered).length;
    final rate = attempts.isEmpty ? 0.0 : remembered / attempts.length;
    final level = attempts.length < 2
        ? MasteryLevel.newWord
        : rate < .5
        ? MasteryLevel.needsPractice
        : attempts.length >= 3 && rate >= .8
        ? MasteryLevel.strong
        : MasteryLevel.learning;
    return WordMastery(word, attempts.length, remembered, level);
  }).toList();
  final days = history
      .map(
        (item) => DateTime(
          item.reviewedAt.year,
          item.reviewedAt.month,
          item.reviewedAt.day,
        ),
      )
      .toSet();
  var cursor = days.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  var current = 0;
  while (days.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  final sortedDays = days.toList()..sort();
  var longest = sortedDays.isEmpty ? 0 : 1;
  var run = longest;
  for (var i = 1; i < sortedDays.length; i++) {
    run = sortedDays[i].difference(sortedDays[i - 1]).inDays == 1 ? run + 1 : 1;
    if (run > longest) longest = run;
  }
  final activity = List.generate(7, (index) {
    final day = today.subtract(Duration(days: 6 - index));
    final next = day.add(const Duration(days: 1));
    final attempts = history.where(
      (item) =>
          !item.reviewedAt.isBefore(day) && item.reviewedAt.isBefore(next),
    );
    return DailyActivity(
      day,
      attempts.length,
      attempts.where((item) => item.remembered).length,
    );
  });
  final upcoming =
      words.where((word) => word.nextReviewAt?.isAfter(now) ?? false).toList()
        ..sort((a, b) => a.nextReviewAt!.compareTo(b.nextReviewAt!));
  return ReviewStatistics(
    totalWords: words.length,
    dueWords: due.length,
    totalReviews: history.length,
    rememberedReviews: history.where((item) => item.remembered).length,
    currentStreak: current,
    longestStreak: longest,
    mastery: mastery,
    activity: activity,
    upcoming: upcoming.take(5).toList(),
  );
});

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
