import 'package:flutter/material.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/pages/debug/debug_page.dart';
import 'package:linko_app/widget/linko_logo.dart';
import 'package:linko_app/widget/responsive_list_view.dart';
import 'package:linko_app/core/navigation/router.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(t.aboutPage.title),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _onLogoTap,
            behavior: HitTestBehavior.opaque,
            child: const LinkoLogo(withText: true),
          ),
          const SizedBox(height: 4),
          const Text(
            'Version 1.0.0 (Latest)',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} saferill',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Linko is a modern, ultra-fast, and secure cross-platform file sharing solution.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  await launchUrl(Uri.parse('https://getlinko.pages.dev'), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.language, size: 18),
                label: const Text('getlinko.pages.dev'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await launchUrl(Uri.parse('https://github.com/saferill/Linko'), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.code, size: 18),
                label: const Text('GitHub Source'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await launchUrl(Uri.parse('https://github.com/saferill/Linko/blob/main/LICENSE'), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.description, size: 18),
                label: const Text('Apache 2.0 License'),
              ),
            ],
          ),
          if (_debugUnlocked) ...[
            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: () async {
                  await context.push(() => const DebugPage());
                },
                child: const Text('Debug Mode'),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
