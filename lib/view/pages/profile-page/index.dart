import 'package:flutter/material.dart';
import 'package:ivo/components/flashcard/deck_preview.dart';
import 'package:ivo/data/l10n.dart';
import 'package:ivo/data/models/flashcard_models.dart';
import 'package:ivo/services/auth/auth_service.dart';
import 'package:ivo/services/flashcard_service.dart';
import 'package:ivo/services/profile_service.dart';
import 'package:ivo/view/pages/settings-page/index.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  final _profile = ProfileService();
  final _flashcard = FlashcardService();

  StudySummary _summary = StudySummary.empty;
  List<FlashcardDeck> _decks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _profile.getStudySummary(),
        _flashcard.getDecks(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as StudySummary;
        _decks = results[1] as List<FlashcardDeck>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = _auth.getCurrentUserEmail() ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: scheme.primary,
          child: _loading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    // ── Avatar + info ────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 84, height: 84,
                            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                            child: Center(
                              child: Text(initials,
                                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(email,
                              style: TextStyle(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                            icon: const Icon(Icons.settings_outlined, size: 16),
                            label: Text(t('profile_settings')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.onSurface,
                              side: BorderSide(color: scheme.outlineVariant),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    _Monolabel(t('profile_stats')),
                    const SizedBox(height: 10),

                    // ── Stats grid ───────────────────────────────────────────
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.9,
                      children: [
                        _StatCard(label: t('profile_total_reviewed'), value: '${_summary.totalReviewed}', scheme: scheme),
                        _StatCard(label: t('profile_streak'), value: '${_summary.streakDays}', scheme: scheme),
                        _StatCard(label: t('profile_active_days'), value: '${_summary.daysActive}', scheme: scheme),
                        _StatCard(
                            label: t('profile_accuracy'),
                            value: '${(_summary.accuracy * 100).round()}%',
                            scheme: scheme),
                      ],
                    ),

                    if (_decks.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _Monolabel(t('profile_my_decks')),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _decks.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => DeckPreview(deck: _decks[i]))),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(_decks[i].name,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    Divider(color: scheme.outlineVariant),
                    const SizedBox(height: 8),

                    // ── Sign out ─────────────────────────────────────────────
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout_rounded, color: scheme.error),
                      title: Text(t('profile_sign_out'), style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
                      onTap: () => _auth.signOut(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final ColorScheme scheme;
  const _StatCard({required this.label, required this.value, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: scheme.onSurface)),
        ],
      ),
    );
  }
}

class _Monolabel extends StatelessWidget {
  final String text;
  const _Monolabel(this.text);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(text.toUpperCase(),
        style: TextStyle(fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.5)));
  }
}
