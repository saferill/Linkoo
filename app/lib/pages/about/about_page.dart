import 'package:flutter/material.dart';
import 'package:linko_app/core/navigation/router.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/pages/debug/debug_page.dart';
import 'package:linko_app/widget/linko_logo.dart';
import 'package:linko_app/widget/responsive_list_view.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _logoTapCount = 0;
  bool _debugUnlocked = false;

  void _onLogoTap() {
    setState(() {
      _logoTapCount++;
      if (_logoTapCount >= 7) {
        _debugUnlocked = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛠️ Developer / Debug Mode Unlocked'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.aboutPage.title),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Hero Bento Branding Card
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onLogoTap,
                  behavior: HitTestBehavior.opaque,
                  child: const LinkoLogo(withText: true),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'v1.0.0 (Latest)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '© ${DateTime.now().year} saferill',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Linko is a modern, ultra-fast, and secure cross-platform file sharing solution.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bento Links Section
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.language, color: colorScheme.onPrimaryContainer, size: 20),
                  ),
                  title: const Text('getlinko.pages.dev', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Official Website', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    await launchUrl(Uri.parse('https://getlinko.pages.dev'), mode: LaunchMode.externalApplication);
                  },
                ),
                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.code, color: colorScheme.onSecondaryContainer, size: 20),
                  ),
                  title: const Text('GitHub Source', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('github.com/saferill/Linko', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    await launchUrl(Uri.parse('https://github.com/saferill/Linko'), mode: LaunchMode.externalApplication);
                  },
                ),
                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description, color: colorScheme.onTertiaryContainer, size: 20),
                  ),
                  title: const Text('Apache 2.0 License', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Free & Open Source', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    await launchUrl(Uri.parse('https://github.com/saferill/Linko/blob/main/LICENSE'), mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
          ),

          if (_debugUnlocked) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    await context.push(() => const DebugPage());
                  },
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Open Debug Mode'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
