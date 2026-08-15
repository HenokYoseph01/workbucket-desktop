import 'package:flutter_test/flutter_test.dart';
import 'package:wordbucket_desktop/data/services/clipboard_capture_service.dart';

void main() {
  final service = ClipboardCaptureService();

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

  test(
    'waits for a copied word to propagate from another application',
    () async {
      final responses = <String?>[null, null, '  Resilient  '];
      final delayedService = ClipboardCaptureService(
        reader: () async => responses.removeAt(0),
        retryDelays: const [Duration.zero, Duration.zero],
      );

      expect(await delayedService.readWord(), 'resilient');
      expect(responses, isEmpty);
    },
  );

  test('reports an empty clipboard after bounded retries', () async {
    var reads = 0;
    final emptyService = ClipboardCaptureService(
      reader: () async {
        reads++;
        return null;
      },
      retryDelays: const [Duration.zero, Duration.zero],
    );

    await expectLater(
      emptyService.readWord(),
      throwsA(isA<ClipboardCaptureException>()),
    );
    expect(reads, 3);
  });
}
