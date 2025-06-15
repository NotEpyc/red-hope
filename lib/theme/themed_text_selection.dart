import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:flutter/foundation.dart';

// Global instance to be used throughout the app
final themedTextSelectionControls = ThemedTextSelectionControls();

class ThemedTextSelectionControls extends MaterialTextSelectionControls {
  // Override to customize the appearance of text selection toolbar
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: Theme.of(context).popupMenuTheme.copyWith(
          color: AppTheme.primaryColor,
          textStyle: TextStyle(
            color: AppTheme.secondaryColor,
            fontSize: 14,
          ),
        ),
      ),
      child: super.buildToolbar(
        context,
        globalEditableRegion,
        textLineHeight,
        selectionMidpoint,
        endpoints,
        delegate,
        clipboardStatus,
        lastSecondaryTapDownPosition,
      ),
    );
  }
}