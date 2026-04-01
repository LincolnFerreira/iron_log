import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth_state.dart';
import '../../../auth/utils/logout_utils.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS  (espelha o CSS do IronLog)
// ─────────────────────────────────────────────
class IronTokens {
  // Dark
  static const bgDark = Color(0xFF0A0A0C);
  static const s1Dark = Color(0xFF111115);
  static const s2Dark = Color(0xFF18181E);
  static const s3Dark = Color(0xFF22222A);
  static const borderDark = Color(0x12FFFFFF);
  static const border2Dark = Color(0x1FFFFFFF);

  // Light
  static const bgLight = Color(0xFFF2F2F5);
  static const s1Light = Color(0xFFFFFFFF);
  static const s2Light = Color(0xFFEAEAEF);
  static const s3Light = Color(0xFFDDDDE5);
  static const borderLight = Color(0x14000000);
  static const border2Light = Color(0x24000000);

  // Accents (same both modes — adjusted via opacity when needed)
  static const accentDark = Color(0xFFE8FF47);
  static const accentLight = Color(0xFF8AB200);
  static const green = Color(0xFF4DFFB4);
  static const greenLight = Color(0xFF00A36E);
  static const red = Color(0xFFFF5252);
  static const redLight = Color(0xFFD93025);
  static const orange = Color(0xFFFF9A3C);
  static const purple = Color(0xFFA78BFA);

  // Text Dark
  static const textDark = Color(0xFFF0F0F0);
  static const text2Dark = Color(0xFFA0A0B0);
  static const text3Dark = Color(0xFF606070);

  // Text Light
  static const textLight = Color(0xFF0F0F14);
  static const text2Light = Color(0xFF50505E);
  static const text3Light = Color(0xFF9090A0);

  static Color accent(bool dark) => dark ? accentDark : accentLight;
  static Color bg(bool dark) => dark ? bgDark : bgLight;
  static Color s1(bool dark) => dark ? s1Dark : s1Light;
  static Color s2(bool dark) => dark ? s2Dark : s2Light;
  static Color s3(bool dark) => dark ? s3Dark : s3Light;
  static Color border(bool dark) => dark ? borderDark : borderLight;
  static Color border2(bool dark) => dark ? border2Dark : border2Light;
  static Color text(bool dark) => dark ? textDark : textLight;
  static Color text2(bool dark) => dark ? text2Dark : text2Light;
  static Color text3(bool dark) => dark ? text3Dark : text3Light;
  static Color greenC(bool dark) => dark ? green : greenLight;
  static Color redC(bool dark) => dark ? red : redLight;
}

// ─────────────────────────────────────────────
//  SETTINGS PAGE
// ─────────────────────────────────────────────
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Staggered fade-in for each section
    _fadeAnims = List.generate(5, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(
          start,
          (start + 0.5).clamp(0, 1),
          curve: Curves.easeOut,
        ),
      );
    });

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final dark = _isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: IronTokens.bg(dark),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── CUSTOM APP BAR ──
            _IronSliverHeader(dark: dark, anim: _fadeAnims[0]),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── PROFILE CARD ──
                  _FadeSlide(
                    animation: _fadeAnims[1],
                    child: _ProfileCard(user: user, dark: dark),
                  ),
                  const SizedBox(height: 28),

                  // ── GENERAL SECTION ──
                  _FadeSlide(
                    animation: _fadeAnims[2],
                    child: _SectionLabel(label: 'Geral', dark: dark),
                  ),
                  const SizedBox(height: 10),
                  _FadeSlide(
                    animation: _fadeAnims[2],
                    child: _SettingsGroup(
                      dark: dark,
                      items: [
                        _SettingItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notificações',
                          sublabel: 'Lembretes de treino',
                          dark: dark,
                          onTap: () => _comingSoon(),
                        ),
                        _SettingItem(
                          icon: Icons.dark_mode_outlined,
                          label: 'Tema',
                          sublabel: 'Claro · Escuro · Automático',
                          dark: dark,
                          onTap: () => _comingSoon(),
                          trailing: _ThemeToggleChip(dark: dark),
                        ),
                        _SettingItem(
                          icon: Icons.language_outlined,
                          label: 'Idioma',
                          sublabel: 'Português (Brasil)',
                          dark: dark,
                          onTap: () => _comingSoon(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── ACCOUNT SECTION ──
                  _FadeSlide(
                    animation: _fadeAnims[3],
                    child: _SectionLabel(label: 'Conta', dark: dark),
                  ),
                  const SizedBox(height: 10),
                  _FadeSlide(
                    animation: _fadeAnims[3],
                    child: _SettingsGroup(
                      dark: dark,
                      items: [
                        _SettingItem(
                          icon: Icons.cloud_upload_outlined,
                          label: 'Backup de Dados',
                          sublabel: 'Sincronizar com a nuvem',
                          dark: dark,
                          onTap: () => _comingSoon(),
                        ),
                        _SettingItem(
                          icon: Icons.shield_outlined,
                          label: 'Privacidade',
                          sublabel: 'Controle seus dados',
                          dark: dark,
                          onTap: () => _comingSoon(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── LOGOUT BUTTON ──
                  _FadeSlide(
                    animation: _fadeAnims[4],
                    child: _LogoutButton(
                      dark: dark,
                      onTap: () => LogoutUtils.showLogoutDialog(context, ref),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── APP VERSION ──
                  _FadeSlide(
                    animation: _fadeAnims[4],
                    child: Center(
                      child: Text(
                        'IronLog v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: IronTokens.text3(dark),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Em breve!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: IronTokens.s2(_isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SLIVER HEADER
// ─────────────────────────────────────────────
class _IronSliverHeader extends StatelessWidget {
  final bool dark;
  final Animation<double> anim;
  const _IronSliverHeader({required this.dark, required this.anim});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 110,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: IronTokens.bg(dark),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: IronTokens.s2(dark),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: IronTokens.border(dark)),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: IronTokens.text(dark),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: FadeTransition(
          opacity: anim,
          child: Text(
            'Configurações',
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: IronTokens.text(dark),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: IronTokens.border(dark)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE CARD
// ─────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final bool dark;
  const _ProfileCard({required this.user, required this.dark});

  @override
  Widget build(BuildContext context) {
    final accent = IronTokens.accent(dark);
    final rawName = (user?.displayName ?? '').trim();
    final initial = rawName.isNotEmpty
        ? rawName.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Subtle gradient — mesmo conceito do HTML
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.09), accent.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.4), width: 2),
              color: IronTokens.s2(dark),
            ),
            child: ClipOval(
              child: user?.photoURL != null
                  ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Usuário',
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: IronTokens.text(dark),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? 'Email não disponível',
                  style: TextStyle(
                    fontSize: 13,
                    color: IronTokens.text3(dark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Edit hint
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: IronTokens.s2(dark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: IronTokens.border2(dark)),
            ),
            child: Icon(
              Icons.edit_outlined,
              size: 16,
              color: IronTokens.text3(dark),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dark;
  const _SectionLabel({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: IronTokens.text3(dark),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SETTINGS GROUP (card container)
// ─────────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final bool dark;
  final List<_SettingItem> items;
  const _SettingsGroup({required this.dark, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IronTokens.s1(dark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IronTokens.border(dark)),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              item,
              if (!isLast)
                Divider(height: 1, indent: 56, color: IronTokens.border(dark)),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SETTING ITEM
// ─────────────────────────────────────────────
class _SettingItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool dark;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.dark,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_SettingItem> createState() => _SettingItemState();
}

class _SettingItemState extends State<_SettingItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _pressed ? IronTokens.s2(widget.dark) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: IronTokens.s2(widget.dark),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: IronTokens.border(widget.dark)),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: IronTokens.text2(widget.dark),
              ),
            ),
            const SizedBox(width: 14),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: IronTokens.text(widget.dark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: IronTokens.text3(widget.dark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing
            widget.trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: IronTokens.text3(widget.dark),
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  THEME TOGGLE CHIP  (inline no item de Tema)
// ─────────────────────────────────────────────
class _ThemeToggleChip extends StatelessWidget {
  final bool dark;
  const _ThemeToggleChip({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: IronTokens.accent(dark).withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: IronTokens.accent(dark).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 13,
            color: IronTokens.accent(dark),
          ),
          const SizedBox(width: 4),
          Text(
            dark ? 'Dark' : 'Light',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: IronTokens.accent(dark),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LOGOUT BUTTON
// ─────────────────────────────────────────────
class _LogoutButton extends StatefulWidget {
  final bool dark;
  final VoidCallback onTap;
  const _LogoutButton({required this.dark, required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final red = IronTokens.redC(widget.dark);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed ? red.withOpacity(0.18) : red.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: red.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 18, color: red),
            const SizedBox(width: 8),
            Text(
              'Sair da conta',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FADE + SLIDE ANIMATION WRAPPER
// ─────────────────────────────────────────────
class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}
