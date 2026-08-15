import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopHotkeyService {
  DesktopHotkeyService();

  final HotKey _bucketifyHotKey = HotKey(
    key: PhysicalKeyboardKey.keyB,
    modifiers: const [HotKeyModifier.control, HotKeyModifier.shift],
    scope: HotKeyScope.system,
  );

  bool _registered = false;
  static const _activationChannel = MethodChannel(
    'com.elst.wordbucket_desktop/activation',
  );

  Future<String?> register({
    required FutureOr<void> Function() onPressed,
  }) async {
    _activationChannel.setMethodCallHandler((call) async {
      if (call.method == 'bucketify') {
        // The GNOME action has already presented the GTK window. Calling the
        // window_manager plugin again can stall under Wayland, which made the
        // first press raise the window without ever reaching clipboard lookup.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await onPressed();
      }
    });

    if (Platform.environment['XDG_SESSION_TYPE'] == 'wayland') {
      return 'On GNOME Wayland, add WordBucket as a GNOME Custom Shortcut.';
    }
    try {
      if (_registered) await hotKeyManager.unregister(_bucketifyHotKey);
      await hotKeyManager.register(
        _bucketifyHotKey,
        keyDownHandler: (_) => unawaited(_activate(onPressed)),
      );
      _registered = true;
      return null;
    } on PlatformException catch (error) {
      return error.message ?? 'Ctrl+Shift+B is already used by another app.';
    } catch (_) {
      return 'The global shortcut is unavailable on this desktop session.';
    }
  }

  Future<void> _activate(FutureOr<void> Function() onPressed) async {
    try {
      await windowManager.show();
      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }
      await windowManager.focus();
    } catch (_) {
      // A failed X11 window operation must not crash the application.
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await onPressed();
  }

  Future<void> unregister() async {
    _activationChannel.setMethodCallHandler(null);
    if (!_registered) return;
    try {
      await hotKeyManager.unregister(_bucketifyHotKey);
    } finally {
      _registered = false;
    }
  }
}
