import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/muzi_character.dart';
import '../models/emotion.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const String _monthlyProductId = 'musiary_premium_monthly';
  static const String _yearlyProductId = 'musiary_premium_yearly';

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String _selectedPlan = _monthlyProductId;

  @override
  void initState() {
    super.initState();
    _initIAP();
  }

  Future<void> _initIAP() async {
    final available = await _iap.isAvailable();
    if (!available) {
      setState(() {
        _isAvailable = false;
        _isLoading = false;
      });
      return;
    }

    // 구매 스트림 리스닝
    _iap.purchaseStream.listen(_onPurchaseUpdate);

    // 상품 목록 조회
    const productIds = {_monthlyProductId, _yearlyProductId};
    final response = await _iap.queryProductDetails(productIds);

    setState(() {
      _products = response.productDetails;
      _isAvailable = true;
      _isLoading = false;
    });
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // 구매 완료 → 프리미엄 업그레이드
        final days = purchase.productID == _yearlyProductId ? 365 : 31;
        if (mounted) {
          await context.read<AuthProvider>().upgradeToPremium(durationDays: days);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프리미엄 구독이 완료되었어요 🎉'),
                backgroundColor: AppTheme.primary,
              ),
            );
            Navigator.pop(context);
          }
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _purchase() async {
    if (!_isAvailable || _products.isEmpty) {
      // 개발/테스트 환경: Google Play 미연결 시 시뮬레이션
      _showDevModeDialog();
      return;
    }

    final product = _products.firstWhere(
      (p) => p.id == _selectedPlan,
      orElse: () => _products.first,
    );

    setState(() => _isPurchasing = true);
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  void _showDevModeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('테스트 모드'),
        content: const Text(
          'Google Play 결제가 연결되지 않은 환경입니다.\n'
          '실제 앱 출시 후에는 정상적으로 결제가 진행됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // 개발 테스트용: 30일 프리미엄 부여
              await context.read<AuthProvider>().upgradeToPremium(durationDays: 30);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('테스트 프리미엄이 적용되었어요 🎉'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('테스트 구독 적용', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPremium = auth.user?.isPremiumActive ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    MuziCharacter(
                      emotion: EmotionType.excited,
                      size: 80,
                      showSpeechBubble: false,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '뮤지어리 프리미엄',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      '뮤지와 더 특별하게 함께해요',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (isPremium) _buildActiveBadge(auth),
                  if (!isPremium) ...[
                    _buildFeatureList(),
                    const SizedBox(height: 24),
                    _buildPlanSelector(),
                    const SizedBox(height: 20),
                    _buildPurchaseButton(),
                    const SizedBox(height: 12),
                    _buildRestoreButton(),
                  ],
                  const SizedBox(height: 24),
                  _buildComparisonTable(),
                  const SizedBox(height: 24),
                  _buildNotice(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBadge(AuthProvider auth) {
    final until = auth.user?.premiumUntil;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            '프리미엄 구독 중',
            style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
            ),
          ),
          if (until != null)
            Text(
              '${until.year}년 ${until.month}월 ${until.day}일까지',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      ('🎵', '무제한 일기', '하루 여러 번 감정을 기록해요'),
      ('✨', '골드·레인보우 뮤지', '프리미엄 전용 특별한 캐릭터'),
      ('☁️', '클라우드 백업', '일기를 안전하게 보관해요'),
      ('📊', '심화 감정 분석', '월별·연도별 상세 통계'),
      ('🚫', '광고 없음', '깔끔한 화면에서 집중해요'),
    ];

    return Column(
      children: features.map((f) => _buildFeatureTile(f.$1, f.$2, f.$3)).toList(),
    );
  }

  Widget _buildFeatureTile(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary,
              )),
              Text(subtitle, style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary,
              )),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('플랜 선택', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
        )),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPlanCard(
              id: _monthlyProductId,
              title: '월간',
              price: '₩3,900',
              period: '/월',
              badge: null,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildPlanCard(
              id: _yearlyProductId,
              title: '연간',
              price: '₩29,000',
              period: '/년',
              badge: '38% 할인',
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                )),
              ),
            if (badge != null) const SizedBox(height: 8),
            Text(title, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            )),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (id == _yearlyProductId)
              const Text(
                '= 월 ₩2,417',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isPurchasing || _isLoading) ? null : _purchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 4,
          shadowColor: AppTheme.primary.withValues(alpha: 0.3),
        ),
        child: _isPurchasing
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                '지금 구독하기 ✨',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: () => _iap.restorePurchases(),
      child: const Text(
        '구매 복원하기',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('무료 vs 프리미엄', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
        )),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildCompRow(header: true, feature: '기능', free: '무료', premium: '프리미엄'),
              _buildCompRow(feature: '일기 작성', free: '1일 1회', premium: '무제한'),
              _buildCompRow(feature: '감정 분석', free: '기본', premium: '심화'),
              _buildCompRow(feature: '음악 추천', free: '✓', premium: '✓'),
              _buildCompRow(feature: '뮤지 스킨', free: '기본 스킨', premium: '전체 스킨'),
              _buildCompRow(feature: '클라우드 백업', free: '✗', premium: '✓'),
              _buildCompRow(feature: '광고', free: '있음', premium: '없음'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompRow({
    bool header = false,
    required String feature,
    required String free,
    required String premium,
  }) {
    final style = header
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)
        : const TextStyle(fontSize: 14, color: AppTheme.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: style)),
          Expanded(
            flex: 2,
            child: Text(free, style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premium,
              style: style.copyWith(
                color: header ? AppTheme.textSecondary : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('유의사항', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary,
          )),
          const SizedBox(height: 6),
          const Text(
            '• 결제는 Google Play 계정으로 청구됩니다.\n'
            '• 구독은 갱신일 24시간 전에 자동으로 갱신됩니다.\n'
            '• Google Play 계정 설정에서 언제든 해지할 수 있습니다.\n'
            '• 해지 시 현재 구독 기간 종료까지 프리미엄 기능을 사용할 수 있습니다.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}
