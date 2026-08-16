import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final palette = ref.watch(themePaletteProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            context,
            Icons.palette_outlined,
            'Appearance',
            'Choose the atmosphere for your reading desk.',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ThemeMode>(
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (value) =>
                    ref.read(themeModeProvider.notifier).setMode(value.first),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, c) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in AppPalette.values)
                      SizedBox(
                        width: (c.maxWidth - 30) / 4,
                        child: _Palette(
                          item: item,
                          selected: item == palette,
                          onTap: () => ref
                              .read(themePaletteProvider.notifier)
                              .setPalette(item),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _heading(
            context,
            Icons.keyboard_command_key,
            'Bucketify shortcut',
            'How desktop capture is triggered.',
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.keyboard),
              title: Text('Ctrl+Shift+B'),
              subtitle: Text(
                'Works inside WordBucket. On GNOME Wayland, configure the same keys as a Custom Shortcut using the command supplied during setup.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          _heading(
            context,
            Icons.info_outline,
            'About',
            'Desktop companion status.',
          ),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.local_library_outlined),
                  title: Text('WordBucket Desktop'),
                  subtitle: Text('Version 1.0.0 · Linux preview'),
                ),
                Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Your words stay local'),
                  subtitle: Text(
                    'Definitions require internet; saved words and review history use the on-device SQLite database.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _heading(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) => Row(
    children: [
      Icon(icon),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(subtitle),
          ],
        ),
      ),
    ],
  );
}

class _Palette extends StatelessWidget {
  const _Palette({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final AppPalette item;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.lightPaper,
              border: Border.all(color: item.seed, width: 8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(item.label, maxLines: 2)),
          if (selected) const Icon(Icons.check_circle, size: 18),
        ],
      ),
    ),
  );
}
