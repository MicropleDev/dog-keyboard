import 'dart:async';
import 'package:flutter/material.dart';


class KeyboardManager {
  static final KeyboardManager _instance = KeyboardManager._internal();

  factory KeyboardManager() => _instance;

  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  late Animation<Offset> _slideAnimation;

  TextEditingController? textEditingController;

  bool _isShiftEnabled = true;
  bool _isCapsLockEnabled = false;
  bool _isNumbersEnabled = false;
  bool _isEmojiEnabled = false;

  Timer? _keyRepeatTimer;
  void Function(void Function())? _internalSetState;

  KeyboardManager._internal();


  void showKeyboard(BuildContext context) {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: Duration.zero,
            child: Material(
              elevation: 2,
              child: SlideTransition(
                position: _slideAnimation,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    _internalSetState = setState;
                    return _buildKeyboard(context);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(_overlayEntry!);
      _animationController!.forward();
    });
  }

  void hideKeyboard() {
    _animationController?.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _animationController?.dispose();
      _animationController = null;
    });
  }

  void _updateKeyboard() {
    _internalSetState?.call(() {});
  }

  Widget _buildKeyboard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final buttonPadding = maxWidth < 400 ? 6.0 : 12.0;
        final keyFontSize = maxWidth < 400 ? 14.0 : 16.0;

        return ClipRRect(
          child: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(8.0),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextInputField(),
              const SizedBox(height: 8),
              ..._buildKeyboardLayout(context, buttonPadding, keyFontSize),
            ],
          ),
          ),
        );
      },
    );
  }

  List<Widget> _buildKeyboardLayout(BuildContext context, double padding, double fontSize) {
    if (_isNumbersEnabled) {
      return [
        _buildKeyRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], padding, fontSize),
        _buildKeyRow(['-', '/', ':', ';', '(', ')', '&', '@', '"'], padding, fontSize),
        Row(
          children: [
            ...['\$', ',', '?', '!', "'", '#', '%', '*', '+']
                .map((key) => Expanded(child: _buildKey(key, padding, fontSize))),
            _buildBackspaceButton(),
          ],
        ),
        _buildLayoutBottomRow(context, isNumber: true),
      ];
    } else if (_isEmojiEnabled) {
      return [
        _buildKeyRow(['😀', '😂', '😍', '🥺', '😭', '😡', '👍', '👏', '🙏', '💪'], padding, fontSize),
        _buildKeyRow(['🎉', '🔥', '❤️', '🎁', '💔', '⭐', '🌟', '✨', '⚡', '🔥'], padding, fontSize),
        _buildKeyRow(['🎈', '🎊', '🎆', '🎇', '🎃', '🎄', '🎁', '🎋', '🎍', '🎎'], padding, fontSize),
        _buildLayoutBottomRow(context, isEmoji: true),
      ];
    } else {
      return [
        _buildKeyRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'], padding, fontSize),
        _buildKeyRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'], padding, fontSize),
        _buildShiftRow(context, padding, fontSize),
        _buildLayoutBottomRow(context),
      ];
    }
  }

  Widget _buildTextInputField() => TextField(
    controller: textEditingController,
    autofocus: true,
    readOnly: true,
    showCursor: true,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      hintText: 'Type here...',
    ),
  );

  Widget _buildKeyRow(List<String> keys, double padding, double fontSize) =>
      Row(
        children: keys.map((key) => Expanded(child: _buildKey(key, padding, fontSize))).toList(),
      );

  Widget _buildShiftRow(BuildContext context, double padding, double fontSize) =>
      Row(
        children: [
          _buildShiftButton(context),
          ...['Z', 'X', 'C', 'V', 'B', 'N', 'M'].map((k) => Expanded(child: _buildKey(k, padding, fontSize))),
          _buildBackspaceButton(),
        ],
      );

  Widget _buildLayoutBottomRow(BuildContext context,
      {bool isNumber = false, bool isEmoji = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (isNumber)
          _buildActionButton(Icons.abc, _toggleNumbers)
        else if (isEmoji)
          _buildActionButton(Icons.abc, _toggleEmoji)
        else
          _buildNumbersButton(),
        if (!isEmoji && !isNumber) _buildEmojiButton(),
        if (isEmoji || isNumber) _buildNumbersButton(),
        _buildSpaceBar(),
        _buildDotButton(),
        _buildActionButton(Icons.keyboard_hide, hideKeyboard),
      ],
    );
  }

  Widget _buildKey(String label, double padding, double fontSize) {
    final displayed = _isCapsLockEnabled || _isShiftEnabled
        ? label.toUpperCase()
        : label.toLowerCase();

    return Padding(
      padding: EdgeInsets.all(padding / 2),
      child: GestureDetector(
        onLongPressStart: (_) => _startKeyRepeat(() => _onKeyPress(displayed)),
        onLongPressEnd: (_) => _stopKeyRepeat(),
        child: FilledButton.tonal(
          onPressed: () => _onKeyPress(displayed),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(padding),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24.0)),
            ),
            elevation: 2,
          ),
          child: Text(displayed, style: TextStyle(fontSize: fontSize)),
        ),
      ),
    );
  }

  Widget _buildShiftButton(BuildContext context) => _buildActionButton(
    Icons.arrow_upward,
    _toggleShift,
    onLongPress: _toggleCapsLock,
    color: _isCapsLockEnabled ? Colors.green : null,
  );

  Widget _buildBackspaceButton() => _buildActionButton(
    Icons.backspace,
    _onBackspacePressed,
    onLongPressStart: (_) => _startKeyRepeat(_onBackspacePressed),
    onLongPressEnd: (_) => _stopKeyRepeat(),
  );

  Widget _buildNumbersButton() => _buildActionButton(Icons.numbers, _toggleNumbers);

  Widget _buildEmojiButton() => _buildActionButton(Icons.emoji_emotions, _toggleEmoji);

  Widget _buildDotButton() => _buildActionButton(Icons.circle, () => _onKeyPress('.'));

  Widget _buildSpaceBar() => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => _onKeyPress(" "),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(12.0),
          elevation: 2,
        ),
        child: const Text(" "),
      ),
    ),
  );

  Widget _buildActionButton(
      IconData icon,
      VoidCallback onPressed, {
        GestureLongPressCallback? onLongPress,
        GestureLongPressStartCallback? onLongPressStart,
        GestureLongPressEndCallback? onLongPressEnd,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onLongPress: onLongPress,
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12.0),
            elevation: 2,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  void _onKeyPress(String key) {
    if (textEditingController == null) return;

    final text = textEditingController!.text;
    final selection = textEditingController!.selection;

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      key,
    );

    textEditingController!.text = newText;
    textEditingController!.selection = TextSelection.fromPosition(
      TextPosition(offset: selection.start + key.length),
    );

    if (_isShiftEnabled && !_isCapsLockEnabled) {
      _isShiftEnabled = false;
      _updateKeyboard();
    }
  }

  void _onBackspacePressed() {
    if (textEditingController == null) return;

    final text = textEditingController!.text;
    final selection = textEditingController!.selection;

    if (selection.isCollapsed && selection.baseOffset > 0) {
      final newText =
      text.replaceRange(selection.baseOffset - 1, selection.baseOffset, '');
      textEditingController!.text = newText;
      textEditingController!.selection = TextSelection.fromPosition(
        TextPosition(offset: selection.baseOffset - 1),
      );
    } else if (!selection.isCollapsed) {
      final newText = text.replaceRange(selection.start, selection.end, '');
      textEditingController!.text = newText;
      textEditingController!.selection =
          TextSelection.fromPosition(TextPosition(offset: selection.start));
    }

    if (textEditingController!.text.isEmpty) {
      _isShiftEnabled = true;
      _updateKeyboard();
    }
  }

  void _toggleShift() {
    _isCapsLockEnabled = false;
    _isShiftEnabled = !_isShiftEnabled;
    _updateKeyboard();
  }

  void _toggleCapsLock() {
    _isCapsLockEnabled = !_isCapsLockEnabled;
    _isShiftEnabled = _isCapsLockEnabled;
    _updateKeyboard();
  }

  void _toggleNumbers() {
    _isNumbersEnabled = !_isNumbersEnabled;
    _isEmojiEnabled = false;
    _updateKeyboard();
  }

  void _toggleEmoji() {
    _isEmojiEnabled = !_isEmojiEnabled;
    _isNumbersEnabled = false;
    _updateKeyboard();
  }

  void _startKeyRepeat(VoidCallback action) {
    _keyRepeatTimer?.cancel();
    action();
    _keyRepeatTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (_) => action(),
    );
  }

  void _stopKeyRepeat() {
    _keyRepeatTimer?.cancel();
    _keyRepeatTimer = null;
  }
}
