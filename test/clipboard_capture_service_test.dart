import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket_desktop/data/services/clipboard_capture_service.dart';

void main() {
  const service = ClipboardCaptureService();

  test('cleans one copied word', () {
    expect(service.normalizeWord('  “Serendipity!”  '), 'serendipity');
  });

  test('rejects copied sentences', () {
    expect(
      () => service.normalizeWord('more than one word'),
      throwsA(
        isA<ClipboardCaptureException>().having(
          (error) => error.message,
          'message',
          contains('single word'),
        ),
      ),
    );
  });
}
