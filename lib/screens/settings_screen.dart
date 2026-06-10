import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'premium_screen.dart';
import 'muzi_shop_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 21, minute: 0);
  bool _lockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _lockEnabled = prefs.getBool('lock_enabled') ?? false;
      final hour = prefs.getInt('notification_hour') ?? 21;
      final minute = prefs.getInt('notification_minute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', _notificationEnabled);
    await prefs.setBool('lock_enabled', _lockEnabled);
    await prefs.setInt('notification_hour', _notificationTime.hour);
    await prefs.setInt('notification_minute', _notificationTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          final isPremium = user?.isPremiumActive ?? false;

          return ListView(
            children: [
              // 계정 프로필 헤더
              _buildProfileHeader(user?.displayNameOrEmail ?? '게스트', user?.email, isPremium),

              _buildSection(
                title: '구독 & 샵',
                children: [
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isPremium ? Colors.amber.shade50 : AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(isPremium ? '✨' : '🔓', style: const TextStyle(fontSize: 18))),
                    ),
                    title: Text(isPremium ? '프리미엄 구독 중' : '프리미엄으로 업그레이드'),
                    subtitle: Text(
                      isPremium
                          ? user?.premiumUntil != null
                              ? '${user!.premiumUntil!.year}년 ${user.premiumUntil!.month}월 ${user.premiumUntil!.day}일까지'
                              : '구독 활성'
                          : '광고 없음 · 클라우드 백업 · 특별 스킨',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPremium ? Colors.amber.shade700 : AppTheme.textSecondary,
                      ),
                    ),
                    trailing: isPremium
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('PREMIUM', style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800, color: Colors.amber.shade700,
                            )),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4966A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('🎵', style: TextStyle(fontSize: 18))),
                    ),
                    title: const Text('뮤지 스킨 샵'),
                    subtitle: const Text('나만의 뮤지 캐릭터를 꾸며봐요', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MuziShopScreen()),
                    ),
                  ),
                ],
              ),

              _buildSection(
                title: '알림',
                children: [
                  SwitchListTile(
                    title: const Text('일기 작성 알림'),
                    subtitle: const Text('매일 일정 시간에 일기 작성을 알려드려요'),
                    value: _notificationEnabled,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (value) {
                      setState(() => _notificationEnabled = value);
                      _saveSettings();
                    },
                  ),
                  if (_notificationEnabled)
                    ListTile(
                      title: const Text('알림 시간'),
                      subtitle: Text(_notificationTime.format(context)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _pickNotificationTime,
                    ),
                ],
              ),

              _buildSection(
                title: '보안',
                children: [
                  SwitchListTile(
                    title: const Text('앱 잠금'),
                    subtitle: const Text('앱 실행 시 PIN 번호를 입력해요'),
                    value: _lockEnabled,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (value) {
                      if (value) {
                        _setupPin();
                      } else {
                        setState(() => _lockEnabled = false);
                        _saveSettings();
                      }
                    },
                  ),
                  if (_lockEnabled)
                    ListTile(
                      title: const Text('PIN 번호 변경'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _changePin,
                    ),
                ],
              ),

              _buildSection(
                title: '데이터',
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primary),
                    title: const Text('클라우드 백업'),
                    subtitle: Text(
                      isPremium ? 'Firebase에 일기를 백업해요' : '프리미엄 전용 기능',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isPremium
                        ? const Icon(Icons.chevron_right_rounded)
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('PRO', style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.amber.shade700,
                            )),
                          ),
                    onTap: isPremium
                        ? _showFeatureComingSoon
                        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                  ),
                ],
              ),

              // 게스트 모드일 때만 계정 연동 섹션 표시
              if (!auth.isLoggedIn)
                _buildSection(
                  title: '계정 연동',
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.orange.shade600, size: 15),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '게스트 모드 중이에요. 계정을 연동하면 보석 결제·구독·클라우드 백업을 이용할 수 있고, 기존 일기 데이터는 그대로 유지돼요.',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade700, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(
                          child: Text('G', style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4285F4),
                          )),
                        ),
                      ),
                      title: const Text('Google 계정으로 연동'),
                      subtitle: const Text('기존 데이터 유지', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.email_outlined, color: AppTheme.primary, size: 20),
                        ),
                      ),
                      title: const Text('이메일로 연동'),
                      subtitle: const Text('기존 데이터 유지', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE500).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('K', style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF3C1E1E),
                          )),
                        ),
                      ),
                      title: const Text('카카오로 연동'),
                      subtitle: const Text('추후 지원 예정', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('준비 중', style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600,
                        )),
                      ),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('카카오 연동은 추후 지원 예정이에요 😊'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                  ],
                ),

              _buildSection(
                title: '계정',
                children: [
                  if (auth.isLoggedIn)
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.red),
                      title: const Text('로그아웃'),
                      onTap: () => _showLogoutDialog(auth),
                    ),
                  if (auth.isLoggedIn)
                    ListTile(
                      leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
                      title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
                      subtitle: const Text('탈퇴 시 모든 데이터가 삭제됩니다', style: TextStyle(fontSize: 12)),
                      onTap: () => _showDeleteAccountDialog(auth),
                    ),
                  if (!auth.isLoggedIn)
                    ListTile(
                      leading: const Icon(Icons.login_rounded, color: AppTheme.primary),
                      title: const Text('로그인 / 회원가입'),
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                ],
              ),

              _buildSection(
                title: '정보 및 법적 고지',
                children: [
                  const ListTile(
                    title: Text('앱 버전'),
                    trailing: Text('1.0.0', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const ListTile(
                    title: Text('개발자'),
                    trailing: Text('박다현 (2023145030)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('개인정보처리방침'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('이용약관'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('뮤지어리 소개'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showAboutAppDialog,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String? email, bool isPremium) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.1), Colors.amber.shade50])
            : null,
        color: isPremium ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium ? Colors.amber.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                    )),
                    if (isPremium) ...[
                      const SizedBox(width: 6),
                      const Text('✨', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                if (email != null)
                  Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(color: Colors.white, child: Column(children: children)),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _pickNotificationTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() => _notificationTime = time);
      _saveSettings();
    }
  }

  Future<void> _setupPin() async {
    final pin = await _showPinDialog('PIN 설정', '4자리 PIN을 입력하세요');
    if (pin != null && pin.length == 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pin', pin);
      setState(() => _lockEnabled = true);
      _saveSettings();
    }
  }

  Future<void> _changePin() async {
    final pin = await _showPinDialog('PIN 변경', '새로운 4자리 PIN을 입력하세요');
    if (pin != null && pin.length == 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pin', pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN이 변경되었습니다.')),
        );
      }
    }
  }

  Future<String?> _showPinDialog(String title, String subtitle) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(hintText: '• • • •', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showFeatureComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중인 기능이에요 😊')),
    );
  }

  void _showLogoutDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?\n로컬에 저장된 일기는 유지됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말로 탈퇴하시겠어요?\n\n'
          '탈퇴 시 모든 일기 데이터와 계정 정보가\n'
          '영구적으로 삭제됩니다.\n\n'
          '(개인정보보호법 제36조에 따른 삭제권 행사)',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await auth.deleteAccount();
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.errorMessage ?? '탈퇴 처리 중 오류가 발생했어요.'),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              }
            },
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog() {
    showAboutDialog(
      context: context,
      applicationName: '뮤지어리',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const Text(
          '뮤지어리는 감정을 음악으로 기록하는 감성 다이어리 앱입니다.\n\n'
          '일기를 쓰고 나만의 감정을 분석받아 보세요.\n\n'
          '개발: 박다현 (2023145030)\n'
          '과목: 프론트엔드프레임워크',
        ),
      ],
    );
  }
}
