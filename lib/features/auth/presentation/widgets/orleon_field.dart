import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGreen = Color(0xFF00E676);
const _kRed = Color(0xFFFF5252);

class OrleonField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final Widget? trailing;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hintText;
  final VoidCallback? onTap;

  const OrleonField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.trailing,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.onTap,
  });

  @override
  State<OrleonField> createState() => _OrleonFieldState();
}

class _OrleonFieldState extends State<OrleonField> {
  late final FocusNode _focusNode;
  bool _focused = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() => _focused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AbsorbPointer(
            absorbing: widget.onTap != null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                border: Border.all(
                  color: hasError
                      ? _kRed
                      : _focused
                          ? _kGreen
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: _focused
                          ? _kGreen
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextFormField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          obscureText: widget.obscureText,
                          readOnly: widget.readOnly,
                          keyboardType: widget.keyboardType,
                          cursorColor: _kGreen,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: widget.hintText,
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            errorStyle: const TextStyle(height: 0, fontSize: 0),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: widget.validator == null
                              ? null
                              : (v) {
                                  final err = widget.validator!(v);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) setState(() => _error = err);
                                  });
                                  return err;
                                },
                        ),
                      ),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              _error!,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kRed,
              ),
            ),
          ),
      ],
    );
  }
}
