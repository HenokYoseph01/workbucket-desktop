import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'ui/screens/desktop_shell.dart';
import 'providers/theme_provider.dart';

class WordBucketDesktopApp extends ConsumerWidget {
  const WordBucketDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themePaletteProvider);
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'WordBucket Desktop',
      debugShowCheckedModeBanner: false,
      theme: buildDesktopTheme(palette, Brightness.light),
      darkTheme: buildDesktopTheme(palette, Brightness.dark),
      themeMode: mode,
      home: const DesktopShell(),
    );
  }
}
