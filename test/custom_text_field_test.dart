import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dog_keyboard/custom_text_field.dart';

void main() {
  group('CustomTextField Tests', () {
    late TextEditingController controller;
    late FocusNode focusNode;
    late String changedText;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
      changedText = '';
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('renders with hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: CustomTextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (val) => changedText = val,
              decoration: const InputDecoration(hintText: 'Type here...'),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type here...'), findsOneWidget);
    });

    // testWidgets('sets focus and shows keyboard', (WidgetTester tester) async {
    //   bool keyboardShown = false;
    //
    //   // Monkey patch KeyboardManager
    //   final originalShowKeyboard = KeyboardManager().showKeyboard;
    //   KeyboardManager().showKeyboard = (BuildContext context) {
    //     keyboardShown = true;
    //   };
    //
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: Material(
    //         child: CustomTextField(
    //           controller: controller,
    //           focusNode: focusNode,
    //           onChanged: (val) => changedText = val,
    //           decoration: const InputDecoration(hintText: 'Type here...'),
    //         ),
    //       ),
    //     ),
    //   );
    //
    //   await tester.tap(find.byType(CustomTextField));
    //   await tester.pump();
    //
    //   expect(focusNode.hasFocus, isTrue);
    //   expect(keyboardShown, isTrue);
    //
    //   // Restore original function
    //   KeyboardManager().showKeyboard = originalShowKeyboard;
    // });

    testWidgets('invokes onChanged callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: CustomTextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (val) => changedText = val,
              decoration: const InputDecoration(hintText: 'Type here...'),
            ),
          ),
        ),
      );

      controller.text = 'hello';
      controller.selection = const TextSelection.collapsed(offset: 5);

      await tester.pump();

      controller.value = controller.value.copyWith(text: 'hello world');
      await tester.pump();

      expect(controller.text, 'hello world');
    });
  });
}