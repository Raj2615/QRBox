import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qrbox/app.dart';

void main() {
  testWidgets('QRBox app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: QRBoxApp()),
    );

    // Basic smoke test — just verify the app builds without crashing
    expect(find.byType(QRBoxApp), findsOneWidget);
  });
}
