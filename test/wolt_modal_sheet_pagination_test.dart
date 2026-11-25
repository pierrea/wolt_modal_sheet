import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

void main() {
  testWidgets(
    'pagination animation does not throw after the sheet is dismissed',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetViewInsets);
      await tester.binding.setSurfaceSize(const Size(393, 852));

      final pageIndex = ValueNotifier<int>(0);
      addTearDown(pageIndex.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    WoltModalSheet.show<void>(
                      context: context,
                      pageIndexNotifier: pageIndex,
                      pageListBuilder: (_) => [
                        WoltModalSheetPage(child: const Text('First page')),
                        WoltModalSheetPage(child: const Text('Second page')),
                      ],
                    );
                  },
                  child: const Text('Open sheet'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      pageIndex.value = 1;
      await tester.pump();

      // Keyboard inset mid-transition rebuilds the switcher and used to
      // replace the in-flight controller without disposing it.
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      await tester.pump();

      navigatorOf(tester).pop();
      await tester.pump();
      // Route exit is 250ms. Pagination is 350ms, so the exit finishes while
      // a leaked controller would still be ticking.
      await tester.pump(const Duration(milliseconds: 260));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    },
  );
}

NavigatorState navigatorOf(WidgetTester tester) {
  return tester.state<NavigatorState>(find.byType(Navigator));
}
