import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// 개인정보처리방침 (개인정보보호법 제30조 준수)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        _buildSection('제1조 (개인정보의 처리 목적)', '''
뮤지어리(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보 보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

1. 회원 가입 및 관리
   - 회원 가입 의사 확인, 회원제 서비스 제공, 회원 자격 유지·관리

2. 서비스 제공
   - 감정 일기 작성 및 저장
   - 감정 기반 음악 추천 서비스 제공
   - 클라우드 백업 서비스 (프리미엄)

3. 유료 서비스 결제 및 이용
   - 결제 확인, 구독 관리, 환불 처리'''),
        _buildSection('제2조 (처리하는 개인정보의 항목)', '''
회사는 개인정보 최소 수집 원칙에 따라 다음의 개인정보 항목만을 처리합니다.

■ 필수 수집 항목
  - 이메일 주소, 닉네임, 서비스 가입·이용 일시

■ 서비스 이용 중 생성 정보
  - 작성한 감정 일기 내용 (텍스트)
  - 감정 분석 결과 (기기 내 처리)
  - 앱 서비스 이용 기록

■ 구글 로그인 시 수집 항목
  - 구글 계정 이메일, 프로필 이름, 프로필 사진 URL

■ 유료 결제 시
  - 결제 정보는 Google Play에서 직접 처리하며, 회사는 결제 완료 여부만 수신합니다.

※ 민감 정보(주민등록번호, 금융 정보 등)는 수집하지 않습니다.'''),
        _buildSection('제3조 (개인정보의 처리 및 보유 기간)', '''
회사는 법령에 따른 개인정보 보유·이용 기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용 기간 내에서 개인정보를 처리·보유합니다.

1. 회원 정보: 회원 탈퇴 시까지 (탈퇴 즉시 삭제)
2. 일기 데이터: 회원 탈퇴 또는 삭제 요청 시 즉시 삭제
3. 결제 정보: 전자상거래법에 따라 5년 보관

※ 관련 법령에 의한 보존 의무가 있는 경우 해당 기간 동안 보존합니다.'''),
        _buildSection('제4조 (개인정보의 제3자 제공)', '''
회사는 정보주체의 개인정보를 제1조에서 명시한 목적 범위 내에서만 처리하며, 다음의 경우에만 제3자에게 제공합니다.

1. 정보주체의 동의가 있는 경우
2. 법률에 특별한 규정이 있거나 법령상 의무를 준수하기 위하여 불가피한 경우

※ 현재 회사는 개인정보를 제3자에게 제공하지 않습니다.'''),
        _buildSection('제5조 (개인정보 처리의 위탁)', '''
회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁합니다.

■ Firebase (Google LLC)
  - 위탁 업무: 인증, 데이터베이스, 클라우드 저장
  - 보유 기간: 회원 탈퇴 시까지

■ Google Play (Google LLC)
  - 위탁 업무: 인앱 결제 처리
  - 보유 기간: 전자상거래법에 따름'''),
        _buildSection('제6조 (정보주체의 권리·의무 및 행사 방법)', '''
정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다.

1. 개인정보 열람 요구
2. 오류 등이 있을 경우 정정 요구
3. 삭제 요구 (회원 탈퇴 시 즉시 처리)
4. 처리 정지 요구

권리 행사 방법:
  - 앱 설정 > 계정 > 회원 탈퇴
  - 또는 고객센터로 서면, 전자우편으로 요청'''),
        _buildSection('제7조 (개인정보의 파기)', '''
회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.

파기 방법:
  - 전자적 파일 형태: 복원이 불가능한 방법으로 영구 삭제
  - 회원 탈퇴 요청 시 Firebase 및 SQLite 데이터 즉시 삭제'''),
        _buildSection('제8조 (개인정보의 안전성 확보 조치)', '''
회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.

1. 개인정보 암호화
   - 비밀번호는 단방향 암호화(해시)하여 저장
   - 중요 데이터는 Firebase Security Rules로 접근 제어

2. 해킹 등에 대비한 기술적 대책
   - Firebase 자체 보안 인프라 활용
   - HTTPS 통신 (전송 구간 암호화)

3. 개인정보 접근 제한
   - 본인 인증된 사용자만 자신의 데이터에 접근 가능
   - Firebase Security Rules로 타인 데이터 접근 차단'''),
        _buildSection('제9조 (개인정보 보호책임자)', '''
회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 정보주체의 개인정보 관련 불만 처리 및 피해 구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.

▶ 개인정보 보호책임자
  - 성명: 박다현
  - 소속: 뮤지어리 개발팀
  - 학번: 2023145030
  - 과목: 프론트엔드프레임워크

정보주체는 회사의 서비스를 이용하면서 발생한 모든 개인정보 보호 관련 문의, 불만 처리, 피해 구제 등에 관한 사항을 개인정보 보호책임자에게 문의하실 수 있습니다.'''),
        _buildSection('제10조 (개인정보 처리방침의 변경)', '''
이 개인정보처리방침은 2025년 1월 1일부터 적용됩니다.

개인정보처리방침이 변경되는 경우 앱 내 공지사항을 통해 7일 이전부터 고지합니다.'''),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '본 개인정보처리방침은 개인정보 보호법 제30조에 의거하여 작성되었습니다.\n'
            '시행일: 2025년 1월 1일',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '개인정보처리방침',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 22,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '뮤지어리(Musiary)는 이용자의 개인정보를 중요시하며,\n'
          '개인정보 보호법을 준수합니다.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

/// 이용약관 화면
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '서비스 이용약관',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 22, color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '뮤지어리 서비스를 이용하기 전에 약관을 읽어주세요.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const Divider(height: 32),
            _buildArticle('제1조 (목적)',
              '이 약관은 뮤지어리(이하 "서비스")가 제공하는 모바일 애플리케이션 서비스의 이용과 관련하여 서비스와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
            ),
            _buildArticle('제2조 (서비스의 제공)',
              '서비스는 다음과 같은 기능을 제공합니다.\n'
              '1. 감정 일기 작성 및 저장\n'
              '2. 감정 기반 음악 추천 (YouTube 스트리밍)\n'
              '3. 감정 통계 및 분석\n'
              '4. 프리미엄 구독 서비스',
            ),
            _buildArticle('제3조 (이용자의 의무)',
              '이용자는 다음 행위를 하여서는 안 됩니다.\n'
              '1. 타인의 개인정보를 무단으로 수집·저장·공개하는 행위\n'
              '2. 서비스를 이용하여 법령 위반 행위\n'
              '3. 서비스의 정상적인 운영을 방해하는 행위',
            ),
            _buildArticle('제4조 (저작권)',
              '서비스가 추천하는 음악의 저작권은 각 아티스트 및 저작권자에게 있습니다. '
              '서비스는 YouTube의 공개 API를 통해 음악을 스트리밍하며, '
              '개인 청취 목적으로만 제공됩니다.',
            ),
            _buildArticle('제5조 (면책)',
              '서비스는 천재지변, 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다. '
              '또한 이용자가 서비스를 통해 기대하는 수익을 얻지 못한 경우에 대해서도 책임을 지지 않습니다.',
            ),
            _buildArticle('부칙',
              '이 약관은 2025년 1월 1일부터 시행됩니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticle(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary,
          )),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(
            fontSize: 13, color: AppTheme.textPrimary, height: 1.6,
          )),
        ],
      ),
    );
  }
}
