import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/config.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/auth/role_widgets.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/form_fields.dart';
import 'package:hawacommand_app/widgets/lang_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Demo sign-up: creates an account stored on this phone and signs in.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _asset = TextEditingController(text: AppConfig.defaultAssetId);
  final _org = TextEditingController();
  AppRole _role = AppRole.driver;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _asset.dispose();
    _org.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    await HapticFeedback.mediumImpact();
    final digits = _phone.text;
    final session = Session(
      name: _name.text.trim(),
      phone: '+91 ${digits.substring(0, 5)} ${digits.substring(5)}',
      role: _role,
      assetId: _role == AppRole.driver
          ? _asset.text.trim().toUpperCase()
          : AppConfig.defaultAssetId,
      orgName: _role == AppRole.school && _org.text.trim().isNotEmpty ? _org.text.trim() : null,
    );
    await ref.read(sessionProvider.notifier).signUp(session);
    if (mounted) context.go(_role.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final tr = context.tr;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hawaSystemUi,
      child: Scaffold(
        backgroundColor: HawaColors.paper,
        appBar: AppBar(
          backgroundColor: HawaColors.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(LucideIcons.chevronLeft, size: 22),
            onPressed: () => context.pop(),
          ),
          title: Text(
            tr('डेमो साइन अप', 'Demo sign up', both: 'Demo sign up'),
            style: tr.style(16, weight: FontWeight.w600),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: LanguageButton(),
            ),
          ],
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottom),
            children: [
              Text(
                tr.primary('नया खाता', 'New account'),
                style: tr.style(30, weight: FontWeight.w700, height: 1.2),
              ),
              Text(
                tr(
                  'डेमो खाता बनाएँ · इसी फ़ोन पर सहेजा जाता है',
                  'Create a demo account · stored on this phone',
                  both: 'Create a demo account · stored on this phone',
                ),
                style: tr.style(14, color: HawaColors.muted),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                style: HawaText.sans(16),
                decoration: hawaInputDecoration(label: tr('नाम', 'Full name')),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? tr('नाम लिखें', 'Enter your name') : null,
              ),
              const SizedBox(height: 12),
              PhoneField(
                controller: _phone,
                validator: (v) => (v == null || v.length != 10)
                    ? tr('10 अंकों का नंबर', 'Enter a 10-digit number')
                    : null,
              ),
              const SizedBox(height: 22),
              Text(
                tr('भूमिका', 'Role'),
                style: tr.style(15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              for (final role in AppRole.values) ...[
                RoleCard(
                  role: role,
                  selected: role == _role,
                  showChevron: false,
                  onTap: () => setState(() => _role = role),
                ),
                const SizedBox(height: 10),
              ],
              if (_role == AppRole.driver) ...[
                const SizedBox(height: 4),
                TextFormField(
                  controller: _asset,
                  textCapitalization: TextCapitalization.characters,
                  style: HawaText.mono(16, weight: FontWeight.w500),
                  decoration: hawaInputDecoration(
                    label: tr('गाड़ी नंबर', 'Vehicle ID'),
                    hint: 'T-12',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? tr('गाड़ी नंबर लिखें', 'Enter the vehicle ID')
                      : null,
                ),
              ],
              if (_role == AppRole.school) ...[
                const SizedBox(height: 4),
                TextFormField(
                  controller: _org,
                  textCapitalization: TextCapitalization.words,
                  style: HawaText.sans(16),
                  decoration: hawaInputDecoration(
                    label: tr('स्कूल का नाम', 'School name'),
                    hint: 'Govt. Sarvodaya Vidyalaya',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              BigActionButton(
                icon: LucideIcons.userPlus,
                labelHi: 'खाता बनाएँ',
                labelEn: 'Create demo account',
                busy: _busy,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
