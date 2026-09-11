import 'package:flutter/material.dart';
import 'package:linko_app/gen/strings.g.dart';
import 'package:linko_app/pages/tabs/history_tab.dart';

class ReceiveHistoryPage extends StatelessWidget {
  const ReceiveHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.receiveHistoryPage.title),
      ),
      body: const HistoryTab(isStandalonePage: true),
    );
  }
}
