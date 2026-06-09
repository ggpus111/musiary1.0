import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/muzi_character.dart';
import '../models/emotion.dart';
import 'privacy_policy_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _showPhoneField = false;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeCtrl.reverse().then((_) {
      setState(() {
        _isSignUp = !_isSignUp;
        _showPhoneField = false;
      });
      _fadeCtrl.forward();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp && !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('개인정보처리방침에 동의해주세요.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isSignUp) {
      success = await auth.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      );
      if (success && mounted) {
        // 이메일 인증 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
        return;
      }
    } else {
      success = await auth.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? '오류가 발생했어요.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _kakaoSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithKakao();
    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.isEmpty || !EmailValidator.validate(_emailCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 먼저 입력해주세요.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendPasswordResetEmail(_emailCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent ? '비밀번호 재설정 이메일을 보냈어요 📧' : '이메일 전송에 실패했어요.'),
          backgroundColor: sent ? AppTheme.primary : Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildForm(),
                  const SizedBox(height: 14),
                  _buildSubmitButton(),
                  if (!_isSignUp) _buildForgotPasswordRow(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildGoogleButton(),
                  const SizedBox(height: 10),
                  _buildKakaoButton(),
                  const SizedBox(height: 20),
                  _buildToggleMode(),
                  const SizedBox(height: 8),
                  _buildGuestButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        MuziCharacter(
          emotion: _isSignUp ? EmotionType.excited : EmotionType.happy,
          size: 82,
          showSpeechBubble: false,
        ),
        const SizedBox(height: 14),
        Text(
          '뮤지어리',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: AppTheme.primary,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isSignUp ? '뮤지와 함께 감성 일기를 시작해요 🎵' : '다시 만났네요! 반가워요 🎵',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isSignUp) ...[
            _buildTextField(
              controller: _nameCtrl,
              label: '닉네임',
              hint: '뮤지가 불러줄 이름이에요',
              icon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '닉네임을 입력해주세요.';
                if (v.trim().length > 20) return '닉네임은 20자 이하여야 해요.';
                return null;
              },
            ),
            const SizedBox(height: 10),
          ],
          _buildTextField(
            controller: _emailCtrl,
            label: '이메일',
            hint: 'hello@musiary.app',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return '이메일을 입력해주세요.';
              if (!EmailValidator.validate(v.trim())) return '올바른 이메일 형식이 아니에요.';
              return null;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _passwordCtrl,
            label: '비밀번호',
            hint: '6자 이상 입력하세요',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textHint,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
              if (v.length < 6) return '비밀번호는 6자 이상이어야 해요.';
              return null;
            },
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 10),
            // 전화번호 선택 입력
            _buildPhoneSection(),
            const SizedBox(height: 14),
            _buildTermsCheckbox(),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showPhoneField = !_showPhoneField),
          child: Row(
            children: [
              Icon(
                _showPhoneField ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '휴대폰 번호 입력 (선택 — 이메일 찾기에 활용)',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        if (_showPhoneField) ...[
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneCtrl,
            label: '휴대폰 번호',
            hint: '010-0000-0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return null; // 선택 사항
              final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length != 11) return '올바른 번호를 입력해주세요.';
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          activeColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  children: [
                    TextSpan(text: '개인정보처리방침 및 이용약관에 동의합니다 '),
                    TextSpan(
                      text: '(내용 보기)',
                      style: TextStyle(
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 3,
            shadowColor: AppTheme.primary.withValues(alpha: 0.4),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(
                  _isSignUp ? '회원가입' : '로그인',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _forgotPassword,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          child: const Text(
            '비밀번호 찾기',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
        Text('|', style: TextStyle(color: Colors.grey.shade300)),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FindEmailScreen()),
          ),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          child: const Text(
            '이메일 찾기',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('또는', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.2)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: auth.isLoading ? null : _googleSignIn,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text('G', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF4285F4),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Google로 계속하기', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKakaoButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _kakaoSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEE500),  // 카카오 공식 노란색
            foregroundColor: const Color(0xFF191919),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF3C1E1E),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('K', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFEE500),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              const Text('카카오로 계속하기', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF191919),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? '이미 계정이 있나요?' : '아직 계정이 없나요?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isSignUp ? '로그인' : '회원가입',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestButton() {
    return TextButton(
      onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
      child: Text(
        '로그인 없이 사용하기 (게스트 모드)',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
