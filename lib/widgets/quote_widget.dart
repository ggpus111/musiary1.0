import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class QuoteWidget extends StatelessWidget {
  const QuoteWidget({super.key});

  static const List<Map<String, String>> _quotes = [
    {'quote': '감정은 숨겨야 할 것이 아니라 이해해야 할 것이다.', 'author': '- 뮤지어리'},
    {'quote': '음악은 언어가 실패하는 곳에서 시작된다.', 'author': '- Heinrich Heine'},
    {'quote': '오늘의 감정이 내일의 나를 만든다.', 'author': '- 뮤지어리'},
    {'quote': '자신의 감정을 인정하는 것은 용기의 행위다.', 'author': '- 뮤지어리'},
    {'quote': '음악은 마음의 언어다.', 'author': '- Ludwig van Beethoven'},
    {'quote': '행복은 작은 것들의 합이다.', 'author': '- 뮤지어리'},
    {'quote': '눈물은 영혼이 씻기는 물이다.', 'author': '- 뮤지어리'},
    {'quote': '감사하는 마음은 기쁨의 문을 연다.', 'author': '- Melody Beattie'},
    {'quote': '숨을 쉬어라. 이 순간도 지나갈 것이다.', 'author': '- 뮤지어리'},
    {'quote': '음악은 시간의 기억이다.', 'author': '- 뮤지어리'},
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final quoteIndex = (today.day + today.month) % _quotes.length;
    final quote = _quotes[quoteIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_quote_rounded, color: AppTheme.primary, size: 20),
                SizedBox(width: 6),
                Text(
                  '오늘의 명언',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '"${quote['quote']}"',
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppTheme.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                quote['author']!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
