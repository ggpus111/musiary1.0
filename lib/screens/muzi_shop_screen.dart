import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/muzi_item.dart';
import '../utils/app_theme.dart';
import '../widgets/muzi_character.dart';
import '../models/emotion.dart';
import 'premium_screen.dart';
import 'gem_shop_screen.dart';

class MuziShopScreen extends StatefulWidget {
  const MuziShopScreen({super.key});

  @override
  State<MuziShopScreen> createState() => _MuziShopScreenState();
}

class _MuziShopScreenState extends State<MuziShopScreen>
    with SingleTickerProviderStateMixin {
  final InAppPurchase _iap = InAppPurchase.instance;
  late TabController _tabCtrl;

  static const _tabs = ['스킨', '머리 장식', '악세사리', '배경'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _iap.purchaseStream.listen(_onPurchaseUpdate);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        final id = purchase.productID;
        if (!mounted) return;
        final auth = context.read<AuthProvider>();

        if (id.startsWith('muzi_skin_')) {
          await auth.unlockSkin(id.replaceFirst('muzi_skin_', ''));
        } else if (id.startsWith('muzi_item_')) {
          await auth.unlockItem(id.replaceFirst('muzi_item_', ''));
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구매 완료! 🎉'), backgroundColor: AppTheme.primary),
        );
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildShopHeader(user, auth),
                ),
                bottom: TabBar(
                  controller: _tabCtrl,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildSkinGrid(user, auth),
                _buildItemGrid(MuziItemCategory.outfit, user, auth),
                _buildItemGrid(MuziItemCategory.accessory, user, auth),
                _buildItemGrid(MuziItemCategory.background, user, auth),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopHeader(MusiaryUser? user, AuthProvider auth) {
    final skin = MuziSkin.all.firstWhere(
      (s) => s.id == (user?.muziSkin ?? 'default'),
      orElse: () => MuziSkin.all.first,
    );
    final outfit = user?.equippedOutfit ?? 'none';
    final accessory = user?.equippedAccessory ?? 'none';
    final background = user?.equippedBackground ?? 'default';
    final bgColors = getBackgroundGradient(background);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColors[0], bgColors.last],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
          child: Row(
            children: [
              // 캐릭터 미리보기
              MuziCharacter(
                emotion: EmotionType.happy,
                size: 90,
                showSpeechBubble: false,
                outfit: outfit,
                accessory: accessory,
                background: 'default', // 헤더 배경이 따로 있으므로 캐릭터는 default
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '뮤지 꾸미기 샵',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: background == 'night_sky' || background == 'galaxy'
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '현재: ${skin.name} ${skin.emoji} · ${_getOutfitName(outfit)} · ${_getAccessoryName(accessory)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: background == 'night_sky' || background == 'galaxy'
                            ? Colors.white70
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const GemShopScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💎', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${user?.gems ?? 0}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: background == 'night_sky' || background == 'galaxy'
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (user?.isPremiumActive ?? false) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('✨ PREMIUM', style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800, color: Colors.amber.shade700,
                            )),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 스킨 탭 ──────────────────────────────────────────
  Widget _buildSkinGrid(MusiaryUser? user, AuthProvider auth) {
    final currentSkin = user?.muziSkin ?? 'default';
    final ownedSkins = user?.ownedSkins ?? ['default'];
    final isPremium = user?.isPremiumActive ?? false;

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: MuziSkin.all.length,
      itemBuilder: (context, index) {
        final skin = MuziSkin.all[index];
        final isOwned = ownedSkins.contains(skin.id);
        final isCurrent = skin.id == currentSkin;
        return _buildSkinCard(skin, isOwned, isCurrent, isPremium, auth);
      },
    );
  }

  Widget _buildSkinCard(MuziSkin skin, bool isOwned, bool isCurrent, bool isPremium, AuthProvider auth) {
    final skinColor = Color(skin.colorValue);

    return GestureDetector(
      onTap: () => _handleSkinTap(skin, isOwned, isCurrent, isPremium, auth),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? skinColor : Colors.grey.shade100,
            width: isCurrent ? 2.5 : 1,
          ),
          boxShadow: isCurrent
              ? [BoxShadow(color: skinColor.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: skinColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(skin.emoji, style: const TextStyle(fontSize: 34))),
                  ),
                  if (isCurrent)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: skinColor, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(skin.name, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isCurrent ? skinColor : AppTheme.textPrimary,
              ), textAlign: TextAlign.center),
              const SizedBox(height: 5),
              _buildSkinBadge(skin, isOwned, isCurrent, isPremium, skinColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkinBadge(MuziSkin skin, bool isOwned, bool isCurrent, bool isPremium, Color skinColor) {
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: skinColor, borderRadius: BorderRadius.circular(10)),
        child: const Text('착용 중', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    if (isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: const Text('장착하기', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    if (skin.isPremiumOnly && !isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
        child: const Text('✨ 프리미엄', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w700)),
      );
    }
    if (skin.isPremiumOnly && isPremium && !isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
        child: const Text('무료 해금', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    if (skin.price == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: const Text('무료', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: skinColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text('₩${skin.price}', style: TextStyle(color: skinColor, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  void _handleSkinTap(MuziSkin skin, bool isOwned, bool isCurrent, bool isPremium, AuthProvider auth) async {
    if (isCurrent) return;
    if (isOwned) {
      await auth.changeSkin(skin.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${skin.name}으로 변경했어요! ${skin.emoji}'),
          backgroundColor: Color(skin.colorValue),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      return;
    }
    if (skin.isPremiumOnly) {
      if (!isPremium) {
        _showPremiumDialog();
      } else {
        await auth.unlockSkin(skin.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${skin.name} 스킨을 해금했어요! ✨'),
            backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating,
          ));
        }
      }
      return;
    }
    _showSkinPurchaseDialog(skin, auth);
  }

  void _showSkinPurchaseDialog(MuziSkin skin, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(skin.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(skin.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text('${skin.description}\n\n가격: ₩${skin.price}\n\n구매 후 즉시 적용돼요!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final available = await _iap.isAvailable();
              if (!available) {
                await auth.unlockSkin(skin.id);
                return;
              }
              final response = await _iap.queryProductDetails({'muzi_skin_${skin.id}'});
              if (response.productDetails.isEmpty) {
                await auth.unlockSkin(skin.id);
                return;
              }
              await _iap.buyConsumable(
                purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
              );
            },
            child: Text('₩${skin.price} 구매', style: const TextStyle(
              color: AppTheme.primary, fontWeight: FontWeight.w800,
            )),
          ),
        ],
      ),
    );
  }

  // ── 아이템 탭 (장식, 악세사리, 배경) ─────────────────
  Widget _buildItemGrid(MuziItemCategory category, MusiaryUser? user, AuthProvider auth) {
    final items = MuziItem.byCategory(category);
    final ownedItems = user?.ownedItems ?? ['ribbon'];
    final isPremium = user?.isPremiumActive ?? false;

    String? current;
    switch (category) {
      case MuziItemCategory.outfit:     current = user?.equippedOutfit;
      case MuziItemCategory.accessory:  current = user?.equippedAccessory;
      case MuziItemCategory.background: current = user?.equippedBackground;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length + 1, // +1 for "none" option
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildNoneCard(category, current, user, auth);
        }
        final item = items[index - 1];
        final isOwned = ownedItems.contains(item.id);
        final isCurrent = item.id == current;
        return _buildItemCard(item, isOwned, isCurrent, isPremium, auth, user);
      },
    );
  }

  Widget _buildNoneCard(MuziItemCategory category, String? current, MusiaryUser? user, AuthProvider auth) {
    final isNone = current == null || current == 'none' || current == 'default';
    return GestureDetector(
      onTap: () => _equipNone(category, auth),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNone ? AppTheme.primary : Colors.grey.shade100,
            width: isNone ? 2.5 : 1,
          ),
          boxShadow: isNone
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                color: Colors.grey.shade50, shape: BoxShape.circle,
              ),
              child: Center(child: Text(
                category == MuziItemCategory.background ? '🌫️' : '✖',
                style: TextStyle(fontSize: 32, color: Colors.grey.shade400),
              )),
            ),
            const SizedBox(height: 10),
            Text(
              category == MuziItemCategory.background ? '기본 배경' : '착용 없음',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isNone ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNone ? AppTheme.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isNone ? '적용 중' : '선택',
                style: TextStyle(
                  color: isNone ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(MuziItem item, bool isOwned, bool isCurrent, bool isPremium, AuthProvider auth, MusiaryUser? user) {
    final itemColor = item.colorValue != null ? Color(item.colorValue!) : AppTheme.primary;

    return GestureDetector(
      onTap: () => _handleItemTap(item, isOwned, isCurrent, isPremium, auth),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? itemColor : Colors.grey.shade100,
            width: isCurrent ? 2.5 : 1,
          ),
          boxShadow: isCurrent
              ? [BoxShadow(color: itemColor.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 배경 아이템은 미니 그라디언트 미리보기
              item.category == MuziItemCategory.background
                  ? _buildBgPreview(item, isCurrent, itemColor)
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 34))),
                        ),
                        if (isCurrent)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: itemColor, shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                            ),
                          ),
                      ],
                    ),
              const SizedBox(height: 10),
              Text(item.name, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isCurrent ? itemColor : AppTheme.textPrimary,
              ), textAlign: TextAlign.center),
              const SizedBox(height: 5),
              _buildItemBadge(item, isOwned, isCurrent, isPremium, itemColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBgPreview(MuziItem item, bool isCurrent, Color itemColor) {
    final colors = getBackgroundGradient(item.id);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28))),
        ),
        if (isCurrent)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: itemColor, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildItemBadge(MuziItem item, bool isOwned, bool isCurrent, bool isPremium, Color itemColor) {
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: itemColor, borderRadius: BorderRadius.circular(10)),
        child: const Text('적용 중', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    if (isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: const Text('적용하기', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    if (item.isPremiumOnly && !isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
        child: const Text('✨ 프리미엄', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w700)),
      );
    }
    if (item.isPremiumOnly && isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
        child: const Text('무료 해금', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 2),
          Text('${item.gemCost}', style: TextStyle(color: itemColor, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _handleItemTap(MuziItem item, bool isOwned, bool isCurrent, bool isPremium, AuthProvider auth) async {
    if (isCurrent) return;
    if (isOwned) {
      await _equipItem(item, auth);
      return;
    }
    if (item.isPremiumOnly) {
      if (!isPremium) {
        _showPremiumDialog();
      } else {
        await auth.unlockItem(item.id);
        await _equipItem(item, auth);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${item.name}을 해금했어요! ${item.emoji}'),
            backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating,
          ));
        }
      }
      return;
    }
    _showGemPurchaseDialog(item, auth);
  }

  Future<void> _equipItem(MuziItem item, AuthProvider auth) async {
    switch (item.category) {
      case MuziItemCategory.outfit:
        await auth.equipItem(outfit: item.id);
        break;
      case MuziItemCategory.accessory:
        await auth.equipItem(accessory: item.id);
        break;
      case MuziItemCategory.background:
        await auth.equipItem(background: item.id);
        break;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${item.name} 적용! ${item.emoji}'),
        backgroundColor: item.colorValue != null ? Color(item.colorValue!) : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _equipNone(MuziItemCategory category, AuthProvider auth) async {
    switch (category) {
      case MuziItemCategory.outfit:
        await auth.equipItem(outfit: 'none');
        break;
      case MuziItemCategory.accessory:
        await auth.equipItem(accessory: 'none');
        break;
      case MuziItemCategory.background:
        await auth.equipItem(background: 'default');
        break;
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('프리미엄 전용 아이템'),
        content: const Text('이 아이템은 프리미엄 구독자만 사용할 수 있어요.\n구독하면 무료로 받을 수 있어요! ✨'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
            },
            child: const Text('프리미엄 보기', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showGemPurchaseDialog(MuziItem item, AuthProvider auth) {
    final userGems = auth.gems;
    final enough = userGems >= item.gemCost;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('💎 보석 필요: ', style: TextStyle(fontSize: 14)),
                Text('${item.gemCost}개', style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary,
                )),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('내 보석: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Text('💎 $userGems개', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: enough ? Colors.green.shade600 : Colors.red.shade400,
                )),
              ],
            ),
            if (!enough) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GemShopScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('💎', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text('보석 충전하기', style: TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          if (enough)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await auth.buyItemWithGems(item.id, item.gemCost);
                if (!mounted) return;
                if (ok) {
                  await _equipItem(item, auth);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${item.name} 구매 완료! 💎-${item.gemCost}'),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('보석이 부족해요 💎'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text('💎 ${item.gemCost} 구매', style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.w800,
              )),
            ),
        ],
      ),
    );
  }

  String _getOutfitName(String id) {
    if (id == 'none') return '장식 없음';
    final item = MuziItem.all.where((i) => i.id == id).firstOrNull;
    return item?.name ?? id;
  }

  String _getAccessoryName(String id) {
    if (id == 'none') return '악세사리 없음';
    final item = MuziItem.all.where((i) => i.id == id).firstOrNull;
    return item?.name ?? id;
  }
}
