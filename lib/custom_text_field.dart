import 'package:flutter/material.dart';
import 'keyboard_manager.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String value) onChanged;
  final InputDecoration decoration;

  const CustomTextField({
    super.key,
    this.hintText = 'Type here...',
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.decoration,
  });

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus) {
        KeyboardManager().textEditingController = widget.controller;
        KeyboardManager().showKeyboard(context);
      }
    });

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.onChanged(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Request focus to the TextField when tapped
        FocusScope.of(context).requestFocus(widget.focusNode);
      },
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        readOnly: true,
        // Prevent the default keyboard from appearing
        decoration: widget.decoration,
        onChanged: widget.onChanged,
      ),
    );
  }
}
