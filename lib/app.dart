import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/screens/desktop_shell.dart';

class WordBucketDesktopApp extends StatelessWidget {
  const WordBucketDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordBucket Desktop',
      debugShowCheckedModeBanner: false,
      theme: buildDesktopTheme(),
      home: const DesktopShell(),
    );
  }
}
