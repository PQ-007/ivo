import 'package:flutter/material.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/data/notifiers.dart';
import 'package:ivo/services/auth/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = AuthService();
  int _dailyLimit = 20;
  int _newPerDay = 10;

  void _changeLanguage(String lang) {
    languageNotifier.value = lang;
    setState(() {});
  }

  Future<void> _showResetPasswordDialog() async {
    final ctrl = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('settings_password_reset_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('settings_password_reset_body'), style: TextStyle(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t('auth_email')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('common_cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('common_send')),
          ),
        ],
      ),
    );
    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      try {
        await _auth.resetPassword(ctrl.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('settings_password_reset_sent'))));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  void _showLimitPicker(String label, int current, void Function(int) onSelect) {
    final options = [10, 20, 30, 50, 100];
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface)),
              const SizedBox(height: 12),
              ...options.map((v) => ListTile(
                title: Text('$v', style: TextStyle(color: scheme.onSurface)),
                trailing: v == current ? Icon(Icons.check, color: scheme.primary) : null,
                onTap: () { Navigator.pop(context); onSelect(v); },
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = _auth.getCurrentUserEmail() ?? '';
    final lang = languageNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('settings_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionLabel(t('settings_appearance')),
          _Card(children: [
            ValueListenableBuilder<bool>(
              valueListenable: isDarkThemeNotifier,
              builder: (_, dark, __) => SwitchListTile(
                title: Text(t('settings_dark_mode')),
                value: dark,
                onChanged: (v) => isDarkThemeNotifier.value = v,
                activeThumbColor: scheme.primary,
              ),
            ),
          ]),

          // ── Language ──────────────────────────────────────────────────
          _SectionLabel(t('settings_language')),
          _Card(children: [
            _LangTile(flag: '🇲🇳', label: t('settings_lang_mn'), code: 'mn', current: lang, onTap: _changeLanguage),
            Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
            _LangTile(flag: '🇺🇸', label: t('settings_lang_en'), code: 'en', current: lang, onTap: _changeLanguage),
            Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
            _LangTile(flag: '🇯🇵', label: t('settings_lang_jp'), code: 'jp', current: lang, onTap: _changeLanguage),
          ]),

          // ── Study ─────────────────────────────────────────────────────
          _SectionLabel(t('settings_study')),
          _Card(children: [
            ListTile(
              title: Text(t('settings_daily_limit')),
              trailing: Text('$_dailyLimit', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
              onTap: () => _showLimitPicker(t('settings_daily_limit'), _dailyLimit, (v) => setState(() => _dailyLimit = v)),
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
            ListTile(
              title: Text(t('settings_new_per_day')),
              trailing: Text('$_newPerDay', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
              onTap: () => _showLimitPicker(t('settings_new_per_day'), _newPerDay, (v) => setState(() => _newPerDay = v)),
            ),
          ]),

          // ── Account ───────────────────────────────────────────────────
          _SectionLabel(t('settings_account')),
          _Card(children: [
            ListTile(
              leading: Icon(Icons.email_outlined, color: scheme.onSurface.withValues(alpha: 0.6)),
              title: Text(email.isEmpty ? '—' : email, style: TextStyle(color: scheme.onSurface)),
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
            ListTile(
              leading: Icon(Icons.lock_outline, color: scheme.onSurface.withValues(alpha: 0.6)),
              title: Text(t('settings_change_password')),
              onTap: _showResetPasswordDialog,
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: scheme.outlineVariant),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: scheme.error),
              title: Text(t('settings_sign_out'), style: TextStyle(color: scheme.error)),
              onTap: _signOut,
            ),
          ]),

          // ── About ─────────────────────────────────────────────────────
          _SectionLabel(t('settings_about')),
          _Card(children: [
            ListTile(
              title: Text(t('settings_version')),
              trailing: Text('1.0.0', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5))),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String flag, label, code, current;
  final void Function(String) onTap;
  const _LangTile({required this.flag, required this.label, required this.code, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = code == current;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      trailing: selected ? Icon(Icons.check_rounded, color: scheme.primary) : null,
      onTap: () => onTap(code),
    );
  }
}
