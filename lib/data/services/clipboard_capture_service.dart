import 'package:flutter/services.dart';

class ClipboardCaptureService {
  const ClipboardCaptureService();

  Future<String> readWord() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return normalizeWord(data?.text);
  }

  String normalizeWord(String? text) {
    final raw = text?.trim() ?? '';
    if (raw.isEmpty) {
      throw const ClipboardCaptureException(
        'Your clipboard is empty. Copy a word, then try again.',
      );
    }

    final cleaned = raw.replaceAll(
      RegExp(r"^[^\p{L}]+|[^\p{L}'’\-]+$", unicode: true),
      '',
    );
    if (cleaned.isEmpty ||
        cleaned.contains(RegExp(r'\s')) ||
        !RegExp(
          r"^[\p{L}]+(?:['’\-][\p{L}]+)*$",
          unicode: true,
        ).hasMatch(cleaned)) {
      throw const ClipboardCaptureException(
        'Copy a single word—not a sentence or paragraph—then try again.',
      );
    }

    return cleaned.toLowerCase();
  }
}

class ClipboardCaptureException implements Exception {
  const ClipboardCaptureException(this.message);

  final String message;
}
