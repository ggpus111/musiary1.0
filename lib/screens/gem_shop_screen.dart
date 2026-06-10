import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/auth_provider.dart';
import '../models/muzi_item.dart';
import '../utils/app_theme.dart';
import '../widgets/muzi_character.dart';
import '../models/emotion.dart';

/// 💎 보석 충전 화면
class GemShopScreen extends StatefulWidget {
  const GemShopScreen({super.key});

  @override
  State<GemShopScreen> createState() => _GemShopScreenState();
}

class _GemShopScreenState extends State<GemShopScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _isPurchasing = false;
  String? _purchasingId;

  @override
  void initState() {
    super.initState();
    _iap.purchaseStream.listen(_onPurchaseUpdate);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        final pack = GemPack.all.firstWhere(
          (p) => p.productId == purchase.productID,
          orElse: () => GemPack.all.first,
        );
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        await auth.earnGems(pack.gemAmount);
        if (!mounted) return;
        _showGemEarnedAnimation(pack.gemAmount);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() {
            _isPurchasing = false;
            _purchasingId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구매에 실패했어요. 다시 시도해주세요.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showGemEarnedAnimation(int amount) {
    setState(() {
      _isPurchasing = false;
      _purchasingId = null;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💎', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              '+$amount 보석 획득!',
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '아이템 구매에 사용해보세요 🎀',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestPurchaseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              '결제를 위해 로그인이 필요해요',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '게스트 모드에서는 보석 결제를 이용할 수 없어요.\n'
              '로그인 후에도 지금까지의 일기 데이터는 그대로 유지됩니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '로그인 / 회원가입',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('나중에', style: TextStyle(color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchasePack(GemPack pack, AuthProvider auth) async {
    // 게스트 모드 차단
    if (!auth.isLoggedIn) {
      _showGuestPurchaseDialog();
      return;
    }
    if (_isPurchasing) return;
    setState(() {
      _isPurchasing = true;
      _purchasingId = pack.productId;
    });

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        // 개발 환경 fallback
        await auth.earnGems(pack.gemAmount);
        if (mounted) _showGemEarnedAnimation(pack.gemAmount);
        return;
      }

      final response = await _iap.queryProductDetails({pack.productId});
      if (response.productDetails.isEmpty) {
        // 테스트 환경 fallback
        await auth.earnGems(pack.gemAmount);
        if (mounted) _showGemEarnedAnimation(pack.gemAmount);
        return;
      }

      await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _purchasingId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구매를 처리할 수 없어요. 잠시 후 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('보석 충전'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return CustomScrollView(
            slivers: [
              // 상단 헤더
              SliverToBoxAdapter(child: _buildHeader(auth)),
              // 어떻게 보석 버나요?
              SliverToBoxAdapter(child: _buildEarnSection()),
              // 보석 팩 목록
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPackCard(GemPack.all[i], auth),
                    ),
                    childCount: GemPack.all.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC4966A), Color(0xFFE8CEAF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          MuziCharacter(
            emotion: EmotionType.excited,
            size: 70,
            showSpeechBubble: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내 보석',
                  style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 6),
                    Text(
                      '${auth.gems}',
                      style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white,
                      ),
                    ),
                    const Text(' 개', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '보석으로 뮤지 꾸미기 아이템을 구매해요!',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 보석을 얻는 방법',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildEarnRow('✏️', '일기 한 편 작성', '+3 💎', '+6 💎 (프리미엄)'),
          const SizedBox(height: 8),
          _buildEarnRow('🔥', '7일 연속 작성', '+15 💎', null),
          const SizedBox(height: 8),
          _buildEarnRow('🎉', '한 달 30개 달성', '+50 💎', null),
          const SizedBox(height: 8),
          _buildEarnRow('🎁', '신규 가입', '+10 💎', '기본 지급'),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 구매 팩 요약 비교
          const Text(
            '💎 구매 팩 비교',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          _buildPackCompareRow('10개', '₩1,000', '개당 100원', false),
          const SizedBox(height: 6),
          _buildPackCompareRow('30개', '₩2,500', '개당 83원  ·  17% 할인', false),
          const SizedBox(height: 6),
          _buildPackCompareRow('50개 +10보너스', '₩4,000', '합계 60개  ·  20% 할인', true),
          const SizedBox(height: 6),
          _buildPackCompareRow('100개 +20보너스', '₩7,000', '합계 120개  ·  30% 할인', false),
        ],
      ),
    );
  }

  Widget _buildPackCompareRow(String gems, String price, String desc, bool highlight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.primary.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: highlight ? Border.all(color: AppTheme.primary.withValues(alpha: 0.2)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💎 $gems',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: highlight ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(price, style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: highlight ? AppTheme.primary : AppTheme.textPrimary,
          )),
          if (highlight) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('인기', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarnRow(String icon, String action, String reward, String? sub) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              if (sub != null)
                Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(reward, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary,
          )),
        ),
      ],
    );
  }

  Widget _buildPackCard(GemPack pack, AuthProvider auth) {
    final isPurchasing = _purchasingId == pack.productId;
    final colors = _packColors(pack);
    final hasBonus = pack.bonusGems > 0;
    final discount = pack.discountPercent;

    return GestureDetector(
      onTap: _isPurchasing ? null : () => _purchasePack(pack, auth),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: pack.isBestValue
              ? Border.all(color: AppTheme.primary, width: 2)
              : Border.all(color: Colors.grey.shade100),
          boxShadow: pack.isBestValue
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))]
              : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // ── 보석 아이콘 ──────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text('💎', style: TextStyle(fontSize: _gemFontSize(pack))),
                  ),
                ),
                // 보너스 뱃지
                if (hasBonus)
                  Positioned(
                    top: -6, right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '+${pack.bonusGems}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // ── 텍스트 정보 ──────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 보석 개수 + 뱃지들
                  Wrap(
                    spacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '💎 ${pack.gemAmount}개',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary,
                        ),
                      ),
                      if (hasBonus)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '+${pack.bonusGems} 보너스',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (pack.isBestValue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '인기',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // 총 수량 (보너스 있을 때)
                  if (hasBonus)
                    Text(
                      '합계 ${pack.totalGems}개 지급',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                    ),
                  // 할인율 & 단가
                  if (discount > 0)
                    Text(
                      '개당 ${(pack.price / pack.totalGems).toStringAsFixed(0)}원  ·  $discount% 할인',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    )
                  else
                    Text(
                      '개당 ${(pack.price / pack.totalGems).toStringAsFixed(0)}원',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── 구매 버튼 ────────────────────────
            SizedBox(
              width: 76,
              height: 44,
              child: ElevatedButton(
                onPressed: (_isPurchasing || isPurchasing) ? null : () => _purchasePack(pack, auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: isPurchasing
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        '₩${_formatPrice(pack.price)}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _packColors(GemPack pack) {
    switch (pack.gemAmount) {
      case 10:  return [const Color(0xFFDFE6E9), const Color(0xFFB2BEC3)];
      case 30:  return [const Color(0xFFE8CEAF), const Color(0xFFC4966A)];
      case 50:  return [const Color(0xFF74B9FF), const Color(0xFF0984E3)];
      case 100: return [const Color(0xFFFDCB6E), const Color(0xFFE17055)];
      default:  return [AppTheme.primary, AppTheme.primary];
    }
  }

  double _gemFontSize(GemPack pack) {
    if (pack.gemAmount >= 100) return 30;
    if (pack.gemAmount >= 50)  return 26;
    if (pack.gemAmount >= 30)  return 22;
    return 20;
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
    }
    return '$price';
  }
}
