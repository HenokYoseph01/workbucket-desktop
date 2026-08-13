import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordbucket_desktop/app.dart';
import 'package:wordbucket_desktop/data/database/database.dart';
import 'package:wordbucket_desktop/providers/word_provider.dart';

void main() {
  testWidgets('desktop shell opens on the bucket', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const WordBucketDesktopApp(),
      ),
    );

    expect(find.text('My Bucket'), findsWidgets);
    expect(find.text('Search or define a word…'), findsOneWidget);
    expect(find.text('Your words'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
