import 'package:flutter/services.dart';

typedef ClipboardTextReader = Future<String?> Function();

class ClipboardCaptureService {
  ClipboardCaptureService({
    ClipboardTextReader? reader,
    this.retryDelays = const [
      Duration(milliseconds: 100),
      Duration(milliseconds: 180),
      Duration(milliseconds: 280),
      Duration(milliseconds: 440),
    ],
  }) : _reader = reader ?? _readSystemClipboard;

  final ClipboardTextReader _reader;
  final List<Duration> retryDelays;

  Future<String> readWord() async {
    Object? lastPlatformError;
    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        final text = await _reader();
        if (text != null && text.trim().isNotEmpty) {
          return normalizeWord(text);
        }
      } on PlatformException catch (error) {
        lastPlatformError = error;
      }

      if (attempt < retryDelays.length) {
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    if (lastPlatformError case final PlatformException error) throw error;
    return normalizeWord(null);
  }

  static Future<String?> _readSystemClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
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
