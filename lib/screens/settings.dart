import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/class_essentials/theme.dart';

class SettingsScreen extends ConsumerWidget{
  final Function(dynamic) logout;

  const SettingsScreen({
    super.key,
    required this.logout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final currentTheme = ref.watch(themeProvider);
    final availableThemes = ThemeManager.getAvailableThemes();

    return Center(
        child: Column(children: [
          const SizedBox(
            height: 100,
          ),
          const Text("Settings (button below is to logout)"),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              logout(context);
            },
          ),

          Text('Theme', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentTheme,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: availableThemes.map((themeId) {
              final theme = ThemeManager.getTheme(themeId);
              return DropdownMenuItem<String>(
                value: themeId,
                child: Row(
                  children: [
                    // Color preview circle
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.lightTheme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(theme.name),
                    if (theme.isPremium) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newTheme) {
              if (newTheme != null) {
                ref.read(themeProvider.notifier).changeTheme(newTheme);
              }
            },
          ),

      ]));
  }
}