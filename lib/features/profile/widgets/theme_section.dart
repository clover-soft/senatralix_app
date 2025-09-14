import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/core/theme/app_theme.dart';
import 'package:sentralix_app/core/theme/theme_provider.dart';

/// Секция переключения темы и seed‑цвета в профиле
class ThemeSection extends ConsumerWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final ctrl = ref.read(themeProvider.notifier);
    final currentSeed = themeState.seedIndex;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Тема приложения',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppThemeMode>(
              value: themeState.mode,
              items: const [
                DropdownMenuItem(
                  value: AppThemeMode.system,
                  child: Text('Системная'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.light,
                  child: Text('Светлая'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.dark,
                  child: Text('Тёмная'),
                ),
              ],
              onChanged: (v) {
                if (v != null) ctrl.setMode(v);
              },
              decoration: const InputDecoration(labelText: 'Режим темы'),
            ),
            const SizedBox(height: 16),
            Text(
              'Цветовая палитра (seed)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: kSeedPalette.length,
              itemBuilder: (context, index) {
                final color = kSeedPalette[index];
                final selected = index == currentSeed;
                return InkWell(
                  onTap: () => ctrl.setSeedIndex(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Colors.transparent,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? const Center(
                            child: Icon(Icons.check, color: Colors.white),
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
