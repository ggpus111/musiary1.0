import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';
import '../models/emotion.dart';
import '../utils/app_theme.dart';
import 'diary_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabController;
  Map<EmotionType, int> _monthStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await context.read<DiaryProvider>().getMonthlyStats(
      _focusedDay.year,
      _focusedDay.month,
    );
    if (mounted) setState(() => _monthStats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 대시보드'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: '달력'),
            Tab(text: '통계'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Consumer<DiaryProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                final entry = provider.getEntryForDate(selectedDay);
                if (entry != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiaryDetailScreen(entry: entry),
                    ),
                  );
                }
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
                provider.loadMonthEntries(focusedDay.year, focusedDay.month);
                _loadStats();
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final entry = provider.getEntryForDate(day);
                  if (entry == null) return null;
                  final emotion = Emotion.fromType(entry.emotion);
                  return Positioned(
                    bottom: 2,
                    child: Text(emotion.emoji, style: const TextStyle(fontSize: 14)),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildSelectedDayInfo(provider)),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDayInfo(DiaryProvider provider) {
    if (_selectedDay == null) {
      return Center(
        child: Text(
          '날짜를 선택하면 그날의 기록을 볼 수 있어요',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final entry = provider.getEntryForDate(_selectedDay!);
    if (entry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📝', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('이 날은 기록이 없어요', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    final emotion = Emotion.fromType(entry.emotion);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DiaryDetailScreen(entry: entry)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: emotion.lightColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(emotion.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emotion.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: emotion.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: emotion.color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_monthStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '이번 달 기록이 없어요\n일기를 작성해 보세요!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy년 M월', 'ko_KR').format(_focusedDay),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('감정 기록 통계', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          _buildPieChart(),
          const SizedBox(height: 24),
          _buildEmotionLegend(),
          const SizedBox(height: 24),
          _buildBarChart(),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _monthStats.values.fold(0, (a, b) => a + b);
    final sections = _monthStats.entries.map((e) {
      final emotion = Emotion.fromType(e.key);
      final percent = e.value / total * 100;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${percent.toInt()}%',
        color: emotion.color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 3),
      ),
    );
  }

  Widget _buildEmotionLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _monthStats.entries.map((e) {
        final emotion = Emotion.fromType(e.key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: emotion.lightColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emotion.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${emotion.label} ${e.value}회',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: emotion.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart() {
    final entries = _monthStats.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('감정별 횟수', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: entries.asMap().entries.map((entry) {
                final emotion = Emotion.fromType(entry.value.key);
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: emotion.color,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                      final emotion = Emotion.fromType(entries[index].key);
                      return Text(emotion.emoji, style: const TextStyle(fontSize: 14));
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}
