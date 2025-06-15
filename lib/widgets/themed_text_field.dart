import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../utils/responsive_utils.dart';

class ThemedTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;
  final String? prefixText;
  final int? maxLines;
  final int? minLines;
  const ThemedTextField({
    Key? key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
    this.onSubmitted,
    this.prefixText,
    this.maxLines = 1,
    this.minLines,
  }) : super(key: key);

  @override
  State<ThemedTextField> createState() => _ThemedTextFieldState();
}

class _ThemedTextFieldState extends State<ThemedTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isMultiline = widget.maxLines != null && widget.maxLines! > 1;      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            widget.label,            style: AppTheme.labelTextStyle.copyWith(
              fontSize: ResponsiveUtils.getSmallTextSize(context) + 1,
              color: Colors.black87,
            ),
          ),
        ),
        Container(          height: isMultiline ? null : ResponsiveUtils.getInputHeight(context) * 0.95, // Allows multiline fields to expand naturally
          decoration: BoxDecoration(
            color: AppTheme.lightBackgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightShadowColor,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            validator: widget.validator,
            onChanged: widget.enabled ? widget.onChanged : null,
            keyboardType: widget.keyboardType,
            focusNode: widget.focusNode,
            textInputAction: widget.textInputAction,
            onEditingComplete: widget.onEditingComplete,
            onFieldSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            scrollPhysics: const AlwaysScrollableScrollPhysics(),
            maxLines: widget.maxLines,
            minLines: widget.minLines,            style: AppTheme.inputTextStyle.copyWith(
              fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
              color: widget.enabled ? Colors.black87 : Colors.grey[600],
            ),
            cursorColor: AppTheme.primaryColor,
            decoration: InputDecoration(
              prefixText: widget.prefixText,              prefixStyle: AppTheme.inputTextStyle.copyWith(
                fontSize: ResponsiveUtils.getBodySize(context) * 0.9,
                color: widget.enabled ? Colors.black87 : Colors.grey[600],
              ),
              prefixIcon: Icon(
                widget.icon, 
                color: AppTheme.primaryColor,
                size: ResponsiveUtils.getIconSize(context) * 0.9,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: ResponsiveUtils.isSmallPhone(context) ? 35 : 45
              ),
              suffixIcon: widget.isPassword && widget.enabled
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.primaryColor,
                      size: ResponsiveUtils.getIconSize(context) * 0.9,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: ResponsiveUtils.isSmallPhone(context) ? 14 : 17
              ),
              filled: true,
              fillColor: AppTheme.lightBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppTheme.lightDividerColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppTheme.lightDividerColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: theme.colorScheme.error.withOpacity(0.5),
                  width: 1
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}