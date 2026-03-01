import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/nickname_service.dart';
import '../../auth/data/auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PermissionStatus _micStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;

  // 알림 설정 (UI only)
  bool _notifyMeasurement = true;
  bool _notifyRanking = false;
  bool _notifyNewCafe = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.status;
    final loc = await Permission.locationWhenInUse.status;
    if (mounted) {
      setState(() {
        _micStatus = mic;
        _locationStatus = loc;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickname = ref.watch(nicknameProvider);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      body: Column(
        children: [
          // ── Custom AppBar ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: top),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.go('/profile'),
                ),
                const Expanded(
                  child: Text(
                    '설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // balance the back button
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // ── 계정 정보 ──────────────────────────────────────────
                _SectionHeader('계정 정보'),
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: '닉네임',
                  trailing: Text(
                    nickname ?? '설정 안 됨',
                    style: TextStyle(
                      fontSize: 14,
                      color: nickname != null ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
                    ),
                  ),
                  onTap: () => _editNickname(context, nickname),
                ),
                _SettingsTile(
                  icon: Icons.mail_outline,
                  title: '이메일',
                  trailing: Text(
                    '익명 사용자',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.badge_outlined,
                  title: '계정 유형',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '무료',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mintGreen,
                      ),
                    ),
                  ),
                ),

                // ── 알림 설정 ──────────────────────────────────────────
                _SectionHeader('알림 설정'),
                _SwitchTile(
                  icon: Icons.notifications_outlined,
                  title: '측정 알림',
                  subtitle: '내 측정이 완료되면 알림',
                  value: _notifyMeasurement,
                  onChanged: (v) => setState(() => _notifyMeasurement = v),
                ),
                _SwitchTile(
                  icon: Icons.bar_chart_outlined,
                  title: '랭킹 변동',
                  subtitle: '내 카페가 랭킹에 진입하면 알림',
                  value: _notifyRanking,
                  onChanged: (v) => setState(() => _notifyRanking = v),
                ),
                _SwitchTile(
                  icon: Icons.add_location_alt_outlined,
                  title: '새 카페 등록',
                  subtitle: '주변에 새 카페가 등록되면 알림',
                  value: _notifyNewCafe,
                  onChanged: (v) => setState(() => _notifyNewCafe = v),
                ),

                // ── 앱 설정 ────────────────────────────────────────────
                _SectionHeader('앱 설정'),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: '다크 모드',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '준비 중',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  title: '언어',
                  trailing: Text(
                    '한국어',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ),

                // ── 권한 관리 ──────────────────────────────────────────
                _SectionHeader('권한 관리'),
                _PermissionTile(
                  icon: Icons.mic_rounded,
                  title: '마이크',
                  subtitle: '소음 수치(dB) 측정에만 사용됩니다',
                  status: _micStatus,
                  onManage: () async {
                    if (_micStatus.isPermanentlyDenied) {
                      await openAppSettings();
                    } else {
                      await Permission.microphone.request();
                    }
                    await _checkPermissions();
                  },
                ),
                _PermissionTile(
                  icon: Icons.location_on_rounded,
                  title: '위치',
                  subtitle: '주변 카페 탐색 및 측정 위치 확인에 사용됩니다',
                  status: _locationStatus,
                  onManage: () async {
                    if (_locationStatus.isPermanentlyDenied) {
                      await openAppSettings();
                    } else {
                      await Permission.locationWhenInUse.request();
                    }
                    await _checkPermissions();
                  },
                ),

                // ── 프리미엄 ───────────────────────────────────────────
                _SectionHeader('프리미엄'),
                _PremiumBanner(),

                // ── 정보 ──────────────────────────────────────────────
                _SectionHeader('정보'),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: '앱 버전',
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: '개인정보 처리방침',
                  showArrow: true,
                  onTap: () => _showPrivacyNotice(context),
                ),
                _SettingsTile(
                  icon: Icons.article_outlined,
                  title: '이용약관',
                  showArrow: true,
                  onTap: () => _showTermsNotice(context),
                ),
                _SettingsTile(
                  icon: Icons.code_outlined,
                  title: '오픈소스 라이선스',
                  showArrow: true,
                  onTap: () => showLicensePage(context: context, applicationName: 'Cafe Vibe'),
                ),

                // ── 계정 ──────────────────────────────────────────────
                _SectionHeader('계정'),
                _DangerTile(
                  icon: Icons.logout_rounded,
                  title: '로그아웃',
                  onTap: () => _confirmLogout(context),
                ),
                _DangerTile(
                  icon: Icons.delete_outline_rounded,
                  title: '회원탈퇴',
                  onTap: () => _confirmDeleteAccount(context),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editNickname(BuildContext context, String? current) {
    final controller = TextEditingController(text: current ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('닉네임 설정'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '사용할 이름을 입력하세요',
            counterText: '',
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              ref.read(nicknameProvider.notifier).set(controller.text.trim());
            }
            Navigator.pop(dialogCtx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(nicknameProvider.notifier).set(controller.text.trim());
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('저장', style: TextStyle(color: AppColors.mintGreen)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('개인정보 처리방침'),
        content: const SingleChildScrollView(
          child: Text(
            '• 마이크로 측정한 음성 데이터는 기기 내 메모리에서만 처리됩니다\n'
            '• dB 수치만 서버에 저장되며 음성 파일은 전송하지 않습니다\n'
            '• 위치 정보는 주변 카페 탐색 목적으로만 사용됩니다\n'
            '• 익명 계정 방식으로 이메일, 이름 등 개인 식별 정보를 수집하지 않습니다',
            style: TextStyle(fontSize: 14, height: 1.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppColors.mintGreen)),
          ),
        ],
      ),
    );
  }

  void _showTermsNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('이용약관'),
        content: const SingleChildScrollView(
          child: Text(
            '1. 본 앱은 카페의 소음 정보를 공유하는 커뮤니티 서비스입니다\n'
            '2. 측정 데이터는 공익 목적으로 공개될 수 있습니다\n'
            '3. 허위 데이터 등록 등 서비스 어뷰징 행위는 제재될 수 있습니다\n'
            '4. 서비스는 사전 예고 없이 변경 또는 종료될 수 있습니다',
            style: TextStyle(fontSize: 14, height: 1.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppColors.mintGreen)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?\n다시 앱을 열면 자동으로 로그인됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go('/onboarding');
            },
            child: const Text('로그아웃', style: TextStyle(color: AppColors.dbVeryLoud)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text(
          '모든 측정 기록이 삭제되고 새로운 사용자로 시작됩니다.\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(nicknameProvider.notifier).clear();
              await ref.read(authRepositoryProvider).deleteAccount();
              if (context.mounted) context.go('/onboarding');
            },
            child: const Text('탈퇴', style: TextStyle(color: AppColors.dbVeryLoud)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Shared widgets
// ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        ),
        trailing: trailing ??
            (showArrow
                ? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400)
                : null),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.mintGreen,
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final PermissionStatus status;
  final VoidCallback onManage;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = status == PermissionStatus.granted;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: AppColors.textSecondary),
        title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.mintGreen.withValues(alpha: 0.1)
                    : AppColors.dbVeryLoud.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isGranted ? '허용됨' : '거부됨',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isGranted ? AppColors.mintGreen : AppColors.dbVeryLoud,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onManage,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 32),
              ),
              child: const Text('관리', style: TextStyle(color: AppColors.mintGreen)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DangerTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: AppColors.dbVeryLoud),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.dbVeryLoud,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5BC8AC), Color(0xFF78C5E8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프리미엄으로 업그레이드',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '광고 없이 더 많은 기능을 사용해 보세요',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '준비 중',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mintGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
