import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../../../core/theme/premium_theme.dart';

const _kGreen  = Color(0xFF00E676);
const _kGreenD = Color(0xFF00C853);

class CreateChildProfileScreen extends StatefulWidget {
  final String clubId;
  const CreateChildProfileScreen({super.key, required this.clubId});

  @override
  State<CreateChildProfileScreen> createState() => _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState extends State<CreateChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _positionCtrl   = TextEditingController();
  DateTime? _dob;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('children.select_dob'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final success = await context.read<ClubProvider>().createChildProfile({
      'club_id': widget.clubId,
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'date_of_birth': _dob!.toIso8601String(),
      'position': _positionCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final border = PremiumTheme.borderSubtle(context);
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: PremiumTheme.surfaceCard(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'children.create_profile_title'.tr(),
          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: onSurface),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar preview
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kGreen, _kGreenD],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kGreen.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded, color: Colors.black, size: 36),
              ),
            ),
            const SizedBox(height: 28),

            _fieldLabel(onSurface, 'children.first_name'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameCtrl,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
              decoration: _inputDecoration(context, 'children.first_name'.tr(), border, onSurface),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'children.required'.tr() : null,
            ),
            const SizedBox(height: 16),

            _fieldLabel(onSurface, 'children.last_name'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lastNameCtrl,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
              decoration: _inputDecoration(context, 'children.last_name'.tr(), border, onSurface),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'children.required'.tr() : null,
            ),
            const SizedBox(height: 16),

            _fieldLabel(onSurface, 'children.select_dob'.tr()),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dob == null
                            ? 'children.select_dob'.tr()
                            : DateFormat('dd MMMM yyyy').format(_dob!),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _dob == null
                              ? onSurface.withValues(alpha: 0.35)
                              : onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _fieldLabel(onSurface, 'children.position_label'.tr()),
            const SizedBox(height: 8),
            TextFormField(
              controller: _positionCtrl,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
              decoration: _inputDecoration(
                  context, 'children.position_hint'.tr(), border, onSurface),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kGreen, _kGreenD]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kGreen.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'children.create_profile_btn'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(Color onSurface, String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.4,
        ),
      );

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint,
    Color border,
    Color onSurface,
  ) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: onSurface.withValues(alpha: 0.35)),
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      );
}
