import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import 'bucket_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 1;
  final _bucketKey = GlobalKey<BucketScreenState>();
  static const _titles = ['Progress', 'My Bucket', 'Settings'];

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

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
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
                            color: desktopGold,
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
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: Text('Progress'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_library_outlined),
                      selectedIcon: Icon(Icons.local_library_rounded),
                      label: Text('My Bucket'),
                    ),
                    NavigationRailDestination(
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
                                const _PlaceholderPage(
                                  icon: Icons.insights_rounded,
                                  title: 'Learning progress',
                                  message:
                                      'Review insights will be connected next.',
                                ),
                                BucketScreen(key: _bucketKey),
                                const _PlaceholderPage(
                                  icon: Icons.tune_rounded,
                                  title: 'Desktop preferences',
                                  message:
                                      'Themes and shortcuts will live here.',
                                ),
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

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(message),
          ],
        ),
      ),
    );
  }
}
