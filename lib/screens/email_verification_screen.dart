import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/muzi_character.dart';
import '../models/emotion.dart';

/// 회원가입 후 이메일 인증 대기 화면
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() async {
    for (int i = 60; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendCooldown = i - 1);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    final auth = context.read<AuthProvider>();
    final verified = await auth.refreshEmailVerification();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 인증이 완료됐어요! 🎉'),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('아직 인증이 완료되지 않았어요. 이메일 링크를 클릭해주세요.'),
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    final auth = context.read<AuthProvider>();
    final sent = await auth.resendEmailVerification();
    if (mounted) {
      setState(() {
        _resendCooldown = 60;
      });
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent ? '인증 이메일을 다시 보냈어요 📧' : '발송에 실패했어요.'),
          backgroundColor: sent ? AppTheme.primary : Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('이메일 인증'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // 뮤지 캐릭터
            MuziCharacter(
              emotion: EmotionType.excited,
              size: 100,
              showSpeechBubble: true,
              overrideMessage: '이메일 확인해줘! 📧\n인증 링크 보냈어!',
            ),
            const SizedBox(height: 32),

            // 안내 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('📧', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '이메일 인증이 필요해요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$email\n\n으로 인증 링크를 보냈어요.\n링크를 클릭하면 인증이 완료돼요!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // 인증 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              '인증 완료 확인',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 재발송 버튼
                  TextButton(
                    onPressed: _resendCooldown > 0 ? null : _resendEmail,
                    child: Text(
                      _resendCooldown > 0
                          ? '재발송 ($_resendCooldown초 후 가능)'
                          : '인증 이메일 다시 보내기',
                      style: TextStyle(
                        color: _resendCooldown > 0 ? AppTheme.textHint : AppTheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 나중에 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
              child: const Text(
                '나중에 인증할게요',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
/// 이메일 찾기 화면 (전화번호 OTP 인증)
// ══════════════════════════════════════════════════════
class FindEmailScreen extends StatefulWidget {
  const FindEmailScreen({super.key});

  @override
  State<FindEmailScreen> createState() => _FindEmailScreenState();
}

class _FindEmailScreenState extends State<FindEmailScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  String? _foundEmail;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 11 && digits.startsWith('010');
  }

  Future<void> _sendOtp() async {
    if (!_isValidPhone(_phoneCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 휴대폰 번호를 입력해주세요. (010-XXXX-XXXX)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    await auth.sendPhoneOtp(
      phoneNumber: _phoneCtrl.text.trim(),
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _otpSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증번호를 발송했어요 📱'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red.shade400),
          );
        }
      },
    );
  }

  Future<void> _verifyAndFind() async {
    if (_otpCtrl.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6자리 인증번호를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final email = await auth.findEmailByPhone(
      phoneNumber: _phoneCtrl.text.trim(),
      smsCode: _otpCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _foundEmail = email;
    });

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 전화번호로 등록된 계정을 찾을 수 없어요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('이메일 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '회원가입 시 등록한\n휴대폰 번호로 이메일을 찾아요.',
              style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 28),

            if (_foundEmail == null) ...[
              // 전화번호 입력
              _buildTextField(
                controller: _phoneCtrl,
                label: '휴대폰 번호',
                hint: '010-0000-0000',
                keyboardType: TextInputType.phone,
                suffix: TextButton(
                  onPressed: (_isLoading || _otpSent) ? null : _sendOtp,
                  child: Text(
                    _otpSent ? '재발송' : '인증 요청',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _otpCtrl,
                  label: '인증번호 6자리',
                  hint: '123456',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndFind,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('이메일 찾기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ] else ...[
              // 이메일 찾기 성공
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    const Text('등록된 이메일을 찾았어요!', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                    )),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _foundEmail!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('로그인으로 이동'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    Widget? suffix,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
