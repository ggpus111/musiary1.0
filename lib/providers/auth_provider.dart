import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/muzi_item.dart';

// ═══════════════════════════════════════════════════
// 카카오 로그인은 developers.kakao.com 앱 등록 후 사용 가능
// 현재는 코드 구조만 구현 (앱 키 등록 전까지 비활성화)
// 활성화 방법: pubspec.yaml kakao_flutter_sdk_user 확인 후
// main()에서 KakaoSdk.init(nativeAppKey: 'YOUR_KEY') 호출
// ═══════════════════════════════════════════════════

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus _status = AuthStatus.unknown;
  MusiaryUser? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // 전화번호 인증용
  String? _verificationId;
  int? _resendToken;

  AuthStatus get status => _status;
  MusiaryUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  int get gems => _user?.gems ?? 0;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _status = AuthStatus.authenticated;
      await _loadUserData(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _user = MusiaryUser.fromMap(doc.data()!);
      } else {
        final firebaseUser = _auth.currentUser!;
        _user = MusiaryUser(
          uid: uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(uid).set(_user!.toMap());
      }
    } catch (e) {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        _user = MusiaryUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
      }
    }
  }

  // ── 이메일/비밀번호 회원가입 ─────────────────────────
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);

      // 이메일 인증 메일 발송
      await credential.user?.sendEmailVerification();

      // 전화번호가 있으면 Firestore에 phone→email 매핑 저장 (이메일 찾기용)
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        await _db.collection('phone_index').doc(_normalizePhone(phoneNumber)).set({
          'email': email,
          'uid': credential.user!.uid,
          'maskedEmail': _maskEmail(email),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      final newUser = MusiaryUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(newUser.uid).set(newUser.toMap());
      _user = newUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e.code);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 이메일/비밀번호 로그인 ───────────────────────────
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e.code);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 구글 로그인 ─────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      _errorMessage = '구글 로그인에 실패했어요. 다시 시도해주세요.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 카카오 로그인 ────────────────────────────────────
  // ✅ STEP A: developers.kakao.com → 앱 만들기 → 네이티브 앱 키 복사
  // ✅ STEP B: 플랫폼 → Android → 패키지명(com.musiary.musiary) + 키 해시 등록
  // ✅ STEP C: main.dart의 KakaoSdk.init() 주석 해제 후 실제 키 입력
  // ✅ STEP D: AndroidManifest.xml의 kakaoYOUR_KAKAO_NATIVE_APP_KEY → 실제 키로 교체
  // ✅ STEP E: 이 함수 안의 주석 블록 해제 (// ▼▼▼ ~ // ▲▲▲ 사이)
  Future<bool> signInWithKakao() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // ▼▼▼ 카카오 등록 완료 후 아래 주석 해제 ▼▼▼
      // import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
      //
      // OAuthToken token;
      // if (await isKakaoTalkInstalled()) {
      //   token = await UserApi.instance.loginWithKakaoTalk();
      // } else {
      //   token = await UserApi.instance.loginWithKakaoAccount();
      // }
      // final kakaoUser = await UserApi.instance.me();
      // final kakaoId = kakaoUser.id.toString();
      // final firebaseEmail = 'kakao_$kakaoId@musiary.kakao';
      // final password = 'muzi_${kakaoId}_kakao';
      // try {
      //   await _auth.signInWithEmailAndPassword(email: firebaseEmail, password: password);
      // } on FirebaseAuthException catch (e) {
      //   if (e.code == 'user-not-found') {
      //     await _auth.createUserWithEmailAndPassword(email: firebaseEmail, password: password);
      //     await _auth.currentUser?.updateDisplayName(
      //       kakaoUser.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
      //     );
      //   }
      // }
      // return true;
      // ▲▲▲ 여기까지 주석 해제 ▲▲▲

      _errorMessage = '카카오 로그인은 앱 키 등록 후 사용할 수 있어요.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 이메일 인증 메일 재발송 ──────────────────────────
  Future<bool> resendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── 이메일 인증 상태 갱신 (사용자가 링크 클릭 후 확인) ─
  Future<bool> refreshEmailVerification() async {
    try {
      await _auth.currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      notifyListeners();
      return verified;
    } catch (e) {
      return false;
    }
  }

  // ── 전화번호로 OTP 발송 (이메일 찾기 / 비밀번호 찾기) ──
  Future<bool> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    _setLoading(true);
    try {
      final formatted = _toInternationalPhone(phoneNumber);
      await _auth.verifyPhoneNumber(
        phoneNumber: formatted,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android 자동 인증
          _verificationId = null;
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_parseAuthError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
      return true;
    } catch (e) {
      onError('OTP 발송에 실패했어요. 전화번호를 확인해주세요.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── 전화번호로 이메일 찾기 (OTP 검증 후) ─────────────
  Future<String?> findEmailByPhone({
    required String phoneNumber,
    required String smsCode,
  }) async {
    _setLoading(true);
    try {
      if (_verificationId == null) {
        _errorMessage = 'OTP 인증 세션이 만료됐어요. 다시 시도해주세요.';
        notifyListeners();
        return null;
      }

      // OTP 검증 (임시 로그인)
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);

      // 전화번호로 이메일 조회
      final normalized = _normalizePhone(phoneNumber);
      final doc = await _db.collection('phone_index').doc(normalized).get();

      if (doc.exists) {
        final maskedEmail = doc.data()?['maskedEmail'] as String?;
        return maskedEmail;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.code == 'invalid-verification-code'
          ? '인증번호가 올바르지 않아요.'
          : _parseAuthError(e.code);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── 비밀번호 재설정 이메일 발송 ─────────────────────
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── 로그아웃 ─────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── 프리미엄 업그레이드 ──────────────────────────────
  Future<void> upgradeToPremium({required int durationDays}) async {
    if (_user == null) return;
    final until = DateTime.now().add(Duration(days: durationDays));
    final updated = _user!.copyWith(isPremium: true, premiumUntil: until);
    await _db.collection('users').doc(_user!.uid).update({
      'isPremium': true,
      'premiumUntil': until.millisecondsSinceEpoch,
    });
    _user = updated;
    notifyListeners();
  }

  // ── 스킨 구매 ────────────────────────────────────────
  Future<void> unlockSkin(String skinId) async {
    if (_user == null) return;
    if (_user!.ownedSkins.contains(skinId)) return;
    final newSkins = List<String>.from(_user!.ownedSkins)..add(skinId);
    await _db.collection('users').doc(_user!.uid).update({'ownedSkins': newSkins});
    _user = _user!.copyWith(ownedSkins: newSkins);
    notifyListeners();
  }

  // ── 스킨 장착 ────────────────────────────────────────
  Future<void> changeSkin(String skinId) async {
    if (_user == null) return;
    if (!_user!.ownedSkins.contains(skinId)) return;
    await _db.collection('users').doc(_user!.uid).update({'muziSkin': skinId});
    _user = _user!.copyWith(muziSkin: skinId);
    notifyListeners();
  }

  // ── 꾸미기 아이템 구매 ───────────────────────────────
  Future<void> unlockItem(String itemId) async {
    if (_user == null) return;
    if (_user!.ownedItems.contains(itemId)) return;
    final newItems = List<String>.from(_user!.ownedItems)..add(itemId);
    await _db.collection('users').doc(_user!.uid).update({'ownedItems': newItems});
    _user = _user!.copyWith(ownedItems: newItems);
    notifyListeners();
  }

  // ── 보석 적립 ────────────────────────────────────────
  Future<void> earnGems(int amount) async {
    if (_user == null || amount <= 0) return;
    final newGems = _user!.gems + amount;
    await _db.collection('users').doc(_user!.uid).update({'gems': newGems});
    _user = _user!.copyWith(gems: newGems);
    notifyListeners();
  }

  // ── 보석 사용 (실패 시 false 반환) ───────────────────
  Future<bool> spendGems(int amount) async {
    if (_user == null || amount <= 0) return false;
    if (_user!.gems < amount) return false;
    final newGems = _user!.gems - amount;
    await _db.collection('users').doc(_user!.uid).update({'gems': newGems});
    _user = _user!.copyWith(gems: newGems);
    notifyListeners();
    return true;
  }

  // ── 보석으로 아이템 구매 ─────────────────────────────
  Future<bool> buyItemWithGems(String itemId, int gemCost) async {
    if (_user == null) return false;
    if (_user!.ownedItems.contains(itemId)) return true; // 이미 보유
    final spent = await spendGems(gemCost);
    if (!spent) return false;
    await unlockItem(itemId);
    return true;
  }

  // ── 꾸미기 아이템 착용 ───────────────────────────────
  Future<void> equipItem({
    String? outfit,
    String? accessory,
    String? background,
  }) async {
    if (_user == null) return;
    final updates = <String, dynamic>{};
    if (outfit != null) updates['equippedOutfit'] = outfit;
    if (accessory != null) updates['equippedAccessory'] = accessory;
    if (background != null) updates['equippedBackground'] = background;
    if (updates.isEmpty) return;
    await _db.collection('users').doc(_user!.uid).update(updates);
    _user = _user!.copyWith(
      equippedOutfit: outfit,
      equippedAccessory: accessory,
      equippedBackground: background,
    );
    notifyListeners();
  }

  // ── 테스트 계정 로그인 (발표·데모용) ─────────────────
  static const _testEmail    = 'demo@musiary.app';
  static const _testPassword = 'musiary1234!';

  Future<bool> signInAsTestAccount() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      UserCredential credential;
      try {
        // 이미 있으면 로그인
        credential = await _auth.signInWithEmailAndPassword(
          email: _testEmail,
          password: _testPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'INVALID_LOGIN_CREDENTIALS') {
          // 없으면 자동 생성
          credential = await _auth.createUserWithEmailAndPassword(
            email: _testEmail,
            password: _testPassword,
          );
          await credential.user?.updateDisplayName('데모 뮤지');
        } else {
          rethrow;
        }
      }
      // 모든 아이템 세팅
      await _seedTestData(credential.user!.uid);
      return true;
    } catch (e) {
      _errorMessage = '테스트 계정 로그인에 실패했어요. ($e)';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _seedTestData(String uid) async {
    final allSkinIds = MuziSkin.all.map((s) => s.id).toList();
    final allItemIds = MuziItem.all.map((i) => i.id).toList();

    final testUser = MusiaryUser(
      uid: uid,
      email: _testEmail,
      displayName: '데모 뮤지',
      createdAt: DateTime.now(),
      gems: 9999,
      isPremium: true,
      premiumUntil: DateTime(2099, 12, 31),
      ownedSkins: allSkinIds,
      ownedItems: allItemIds,
      equippedOutfit: 'crown',
      equippedAccessory: 'heart_glasses',
      equippedBackground: 'sakura',
      muziSkin: 'gold',
    );

    await _db.collection('users').doc(uid).set(testUser.toMap());
    _user = testUser;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // ── 로그인 방식 확인 ──────────────────────────────────
  String? get loginProvider {
    final providers = _auth.currentUser?.providerData.map((p) => p.providerId).toList() ?? [];
    if (providers.contains('google.com')) return 'google';
    if (providers.contains('password')) return 'password';
    return null;
  }

  // ── 회원 탈퇴 (재인증 포함) ───────────────────────────
  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    try {
      await _db.collection('users').doc(_user!.uid).delete();
      if (_user!.phoneNumber != null) {
        await _db.collection('phone_index')
            .doc(_normalizePhone(_user!.phoneNumber!))
            .delete();
      }
      await _auth.currentUser?.delete();
      return true;
    } catch (e) {
      _errorMessage = '회원 탈퇴 중 오류가 발생했어요. 재로그인 후 다시 시도해주세요.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reauthAndDeleteAccount({String? password}) async {
    if (_user == null) return false;
    _setLoading(true);
    _errorMessage = null;
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return false;

      final provider = loginProvider;
      if (provider == 'google') {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _setLoading(false);
          return false;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await firebaseUser.reauthenticateWithCredential(credential);
      } else if (provider == 'password' && password != null) {
        final credential = EmailAuthProvider.credential(
          email: _user!.email,
          password: password,
        );
        await firebaseUser.reauthenticateWithCredential(credential);
      }

      await _db.collection('users').doc(_user!.uid).delete();
      if (_user!.phoneNumber != null) {
        await _db.collection('phone_index')
            .doc(_normalizePhone(_user!.phoneNumber!))
            .delete();
      }
      await firebaseUser.delete();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.code == 'wrong-password'
          ? '비밀번호가 틀렸어요.'
          : '인증에 실패했어요. 다시 시도해주세요.';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = '회원 탈퇴 중 오류가 발생했어요.';
      _setLoading(false);
      return false;
    }
  }

  // ── 유틸 ─────────────────────────────────────────────
  String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  String _toInternationalPhone(String phone) {
    final digits = _normalizePhone(phone);
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    return '+82$digits';
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final localPart = parts[0];
    final domain = parts[1];
    if (localPart.length <= 2) return '${localPart[0]}*@$domain';
    return '${localPart.substring(0, 2)}${'*' * (localPart.length - 2)}@$domain';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _parseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':   return '이미 사용 중인 이메일이에요.';
      case 'invalid-email':          return '이메일 형식이 올바르지 않아요.';
      case 'weak-password':          return '비밀번호는 6자 이상이어야 해요.';
      case 'user-not-found':         return '등록되지 않은 이메일이에요.';
      case 'wrong-password':         return '비밀번호가 틀렸어요.';
      case 'too-many-requests':      return '잠시 후 다시 시도해주세요.';
      case 'network-request-failed': return '네트워크 연결을 확인해주세요.';
      case 'invalid-phone-number':   return '올바른 전화번호 형식이 아니에요.';
      case 'quota-exceeded':         return 'SMS 발송 한도를 초과했어요. 잠시 후 시도해주세요.';
      default:                       return '오류가 발생했어요. 다시 시도해주세요.';
    }
  }
}
