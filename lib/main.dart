import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/diary_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (google-services.json 필요)
  await Firebase.initializeApp();

  // 카카오 SDK 초기화 (developers.kakao.com 등록 후 실제 키로 교체)
  // KakaoSdk.init(nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY');

  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 세로 방향 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MusiaryApp());
}

class MusiaryApp extends StatelessWidget {
  const MusiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: '뮤지어리',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const MainNavigation(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
