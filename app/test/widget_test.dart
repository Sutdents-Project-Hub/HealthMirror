import 'package:flutter_test/flutter_test.dart';
import 'package:health_mirror/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HealthMirror renders main navigation', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HealthMirrorApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('HealthMirror'), findsOneWidget);
    expect(find.text('總覽'), findsOneWidget);
    expect(find.text('資料'), findsOneWidget);
    expect(find.text('週報'), findsOneWidget);
    expect(find.text('目標'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('未來自我投射'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    expect(find.text('模擬資料'), findsOneWidget);
    expect(find.text('一鍵 Random 生成資料'), findsOneWidget);
  });
}
