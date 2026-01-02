// URL Managerのウィジェットテスト。
// アプリが正常に起動できることを確認するスモークテスト。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:url_manager/main.dart';

void main() {
  testWidgets('アプリが正常に起動する', (WidgetTester tester) async {
    // アプリをビルドしてフレームをトリガー。
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // アプリが起動し、ナビゲーションバーが表示されることを確認。
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
