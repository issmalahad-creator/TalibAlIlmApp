import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/screens/knowledge/fiqh_tree_screen.dart';

/// ش2–ش3 (docs/KNOWLEDGE_TREE_ZAD_PLAN.md): the Zad tree is drawn by the
/// shared KnowledgeTree3D, and a ruling opens «السلسلة» — the matn, al-Rawd,
/// and the chapter's evidence from Bulugh al-Maram.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('leaf labels: the start of the ruling, the rest behind the tap', () {
    expect(leafLabel('المياه ثلاثة: طهور لا يرفع الحدث ولا يزيل النجس الطارئ غيره.'), 'المياه ثلاثة: طهور لا يرفع الحدث ولا…');
    expect(leafLabel('وهي ارتفاع الحدث.'), 'وهي ارتفاع الحدث');
  });

  test('the matn\'s ruling word picks a fixed colour; no ruling word, no colour', () {
    expect(rulingStyle(const []), isNull);
    expect(rulingStyle(const ['يُكره'])!.$2, isNot(rulingStyle(const ['يُسنّ'])!.$2));
  });

  testWidgets('the tree opens with its chapters, and a ruling opens the chain', (t) async {
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(const MediaQuery(
      data: MediaQueryData(size: Size(400, 900), disableAnimations: true),
      child: MaterialApp(home: FiqhTreeScreen()),
    ));
    for (var i = 0; i < 30 && find.text('المياه').evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(find.text('المياه'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(find.text(leafLabel('المياه ثلاثة: طهور لا يرفع الحدث ولا يزيل النجس الطارئ غيره وهو الباقي على خلقته.')));
    await t.pumpAndSettle();
    expect(find.text(basicText('ft_matn', 'ar')), findsOneWidget);
    expect(find.text(basicText('ft_sharh', 'ar')), findsOneWidget);
    await t.dragUntilVisible(find.text(basicText('ft_evidence', 'ar')), find.byType(ListView).last, const Offset(0, -300));
    await t.pumpAndSettle();
    expect(find.text(basicText('ft_evidence', 'ar')), findsOneWidget);
    expect(find.textContaining('مَاؤُهُ'), findsWidgets); // hadith 1 of Bulugh in the evidence
  });
}
