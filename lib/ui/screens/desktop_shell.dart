import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/services/desktop_hotkey_service.dart';
import '../../data/services/clipboard_capture_service.dart';
import '../../providers/word_provider.dart';
import 'bucket_screen.dart';
import 'compact_definition_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  int _selectedIndex = 1;
  final _bucketKey = GlobalKey<BucketScreenState>();
  final _hotkeyService = DesktopHotkeyService();
  bool _compact = false;
  Size? _normalSize;
  Offset? _normalPosition;
  static const _titles = ['Progress', 'My Bucket', 'Settings'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerHotkey());
  }

  Future<void> _registerHotkey() async {
    final error = await _hotkeyService.register(
      onPressed: _defineCompactClipboard,
    );
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Global shortcut unavailable: $error')),
    );
  }

  @override
  void dispose() {
    unawaited(_hotkeyService.unregister());
    super.dispose();
  }

  void _defineClipboard() {
    if (_selectedIndex != 1) {
      setState(() => _selectedIndex = 1);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _bucketKey.currentState?.defineClipboard(),
      );
      return;
    }
    _bucketKey.currentState?.defineClipboard();
  }

  Future<void> _defineCompactClipboard() async {
    try {
      final word = await ClipboardCaptureService().readWord();
      ref.read(lookupProvider.notifier).clear();
      ref.read(lookupProvider.notifier).lookUp(word);
      _normalSize ??= await windowManager.getSize();
      _normalPosition ??= await windowManager.getPosition();
      if (mounted) setState(() => _compact = true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSize(const Size(480, 440));
      await windowManager.setAlignment(Alignment.topRight);
      // GNOME 46 may refuse focus without a Wayland activation token, but
      // show/always-on-top still improves visibility where the compositor
      // permits it. Do not block clipboard lookup on either request.
      unawaited(windowManager.show());
      unawaited(windowManager.focus());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ClipboardCaptureException
                ? error.message
                : 'Could not open compact Bucketify.',
          ),
        ),
      );
    }
  }

  Future<void> _restoreFullApp() async {
    if (mounted) setState(() => _compact = false);
    await windowManager.setAlwaysOnTop(false);
    if (_normalSize case final size?) await windowManager.setSize(size);
    if (_normalPosition case final position?) {
      await windowManager.setPosition(position);
    }
  }

  Future<void> _returnToReading() async {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    if (_compact) {
      return CompactDefinitionScreen(
        onOpenApp: _restoreFullApp,
        onReturnToReading: _returnToReading,
      );
    }
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    final dueCount = ref.watch(dueWordsProvider).valueOrNull?.length ?? 0;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyB, control: true, shift: true):
            DefineClipboardIntent(),
      },
      child: Actions(
        actions: {
          DefineClipboardIntent: CallbackAction<DefineClipboardIntent>(
            onInvoke: (_) {
              _defineClipboard();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  extended: wide,
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 22, 12, 28),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_library_rounded),
                        ),
                        if (wide) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'WordBucket',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: dueCount > 0,
                        label: Text('$dueCount'),
                        child: const Icon(Icons.insights_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: dueCount > 0,
                        label: Text('$dueCount'),
                        child: const Icon(Icons.insights_rounded),
                      ),
                      label: Text('Progress'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.local_library_outlined),
                      selectedIcon: Icon(Icons.local_library_rounded),
                      label: Text('My Bucket'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.tune_outlined),
                      selectedIcon: Icon(Icons.tune_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _titles[_selectedIndex],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _defineClipboard,
                                icon: const Icon(
                                  Icons.content_paste_go_rounded,
                                ),
                                label: const Text(
                                  'Define clipboard  ·  Ctrl+Shift+B',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep reading. Capture the words worth remembering.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: IndexedStack(
                              index: _selectedIndex,
                              children: [
                                const ProgressScreen(),
                                BucketScreen(key: _bucketKey),
                                const SettingsScreen(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DefineClipboardIntent extends Intent {
  const DefineClipboardIntent();
}
