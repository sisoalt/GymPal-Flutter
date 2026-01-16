import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Consumer<ThemeProvider>(
              builder: (context, themeProv, _) => SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use a dark color scheme for the app'),
                secondary: const Icon(Icons.brightness_6),
                value: themeProv.isDark,
                onChanged: (v) => themeProv.setDark(v),
              ),
            ),
            const SizedBox(height: 12),
            // Placeholder for more preferences
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App theme settings'),
              subtitle: Text('More options coming soon'),
            ),
          ],
        ),
      ),
    );
  }
}
