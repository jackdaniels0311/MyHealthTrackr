import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthtrackr/services/weight_history_service.dart';
import 'package:myhealthtrackr/widgets/weight_progress_card.dart';

void main() {
  final entries = <WeightEntryData>[
    WeightEntryData(
      id: 1,
      userId: 1,
      weightKg: 82.4,
      recordedAt: DateTime(2026, 1, 1),
    ),
    WeightEntryData(
      id: 2,
      userId: 1,
      weightKg: 80.2,
      recordedAt: DateTime(2026, 2, 1),
    ),
    WeightEntryData(
      id: 3,
      userId: 1,
      weightKg: 78.7,
      recordedAt: DateTime(2026, 3, 1),
    ),
  ];

  Future<void> pumpCard(
    WidgetTester tester, {
    required Size size,
    double textScaleFactor = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: WeightProgressCard(entries: entries),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('weight card renders on narrow high-text-scale phones', (
    tester,
  ) async {
    await pumpCard(tester, size: const Size(320, 640), textScaleFactor: 1.6);

    expect(find.text('Weight progress'), findsOneWidget);
    expect(
      _tileTop(tester, 'Starting weight'),
      _tileTop(tester, 'Current weight'),
    );
    expect(_tileTop(tester, 'Current weight'), _tileTop(tester, 'Progress'));
    expect(
      _tileHeight(tester, 'Starting weight'),
      _tileHeight(tester, 'Current weight'),
    );
    expect(
      _tileHeight(tester, 'Current weight'),
      _tileHeight(tester, 'Progress'),
    );
    expect(_textTop(tester, '82.4 kg'), _textTop(tester, '78.7 kg'));
    expect(_textTop(tester, '78.7 kg'), _textTop(tester, '-3.7 kg'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('weight card renders in landscape width without overflow', (
    tester,
  ) async {
    await pumpCard(tester, size: const Size(844, 390), textScaleFactor: 1.3);

    expect(find.text('Log weight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

double _tileTop(WidgetTester tester, String text) {
  return _textTop(tester, text);
}

double _textTop(WidgetTester tester, String text) {
  return tester.getTopLeft(find.text(text)).dy;
}

double _tileHeight(WidgetTester tester, String text) {
  final tile = find
      .ancestor(of: find.text(text), matching: find.byType(Container))
      .first;
  return tester.getSize(tile).height;
}
