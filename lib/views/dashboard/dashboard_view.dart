import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/loading_widget.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final stats = dashboardProvider.stats;

    return MainLayout(
      title: AppStrings.dashboard,
      subtitle: 'Real-time overview of water plants, 6-month service schedules, and maintenance operations',
      headerActions: [
        IconButton(
          tooltip: 'Refresh Stats',
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: () => dashboardProvider.loadStats(),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => context.go(RouteNames.addCustomer),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Customer'),
        ),
      ],
      child: dashboardProvider.isLoading || stats == null
          ? const LoadingWidget(message: 'Loading dashboard analytics...')
          : RefreshIndicator(
              onRefresh: () => dashboardProvider.loadStats(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overdue Services Alert Banner (if overdue > 0)
                    if (stats.overdueServices > 0) ...[
                      _buildOverdueBanner(context, stats.overdueServices),
                      const SizedBox(height: 24),
                    ],

                    // Top 6 Summary Cards
                    _buildStatsGrid(context, stats),
                    const SizedBox(height: 24),

                    // Charts Row (Service Activity Bar Chart & Plant Types Breakdown)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 950) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildServiceActivityCard(stats)),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: _buildPlantDistributionCard(stats)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildServiceActivityCard(stats),
                              const SizedBox(height: 24),
                              _buildPlantDistributionCard(stats),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Tables Row: Upcoming Schedules & Recent Completed
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 950) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildUpcomingScheduleCard(context, stats)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildRecentCustomersCard(context, stats)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildUpcomingScheduleCard(context, stats),
                              const SizedBox(height: 24),
                              _buildRecentCustomersCard(context, stats),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverdueBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attention: $count Water Treatment Plant Service${count > 1 ? 's are' : ' is'} Overdue!',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Immediate filter inspection and chemical maintenance is recommended to prevent membrane scaling.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => context.go(RouteNames.upcomingServices),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.danger),
            label: const Text(
              'View Overdue',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic stats) {
    final cards = [
      DashboardStatCard(
        title: 'Total Customers',
        value: '${stats.totalCustomers}',
        subtitle: 'Active corporate & domestic',
        icon: Icons.people_outline_rounded,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.secondaryLight,
        onTap: () => context.go(RouteNames.customers),
      ),
      DashboardStatCard(
        title: 'Installed Plants',
        value: '${stats.totalInstalledPlants}',
        subtitle: 'RO, Softeners, DM & STP',
        icon: Icons.precision_manufacturing_outlined,
        iconColor: AppColors.secondary,
        iconBgColor: AppColors.secondaryLight,
        onTap: () => context.go(RouteNames.customers),
      ),
      DashboardStatCard(
        title: 'Upcoming Services',
        value: '${stats.upcomingServices}',
        subtitle: 'Next 6-month cycles',
        icon: Icons.pending_actions_rounded,
        iconColor: AppColors.success,
        iconBgColor: AppColors.successLight,
        onTap: () => context.go(RouteNames.upcomingServices),
      ),
      DashboardStatCard(
        title: 'Overdue Services',
        value: '${stats.overdueServices}',
        subtitle: stats.overdueServices > 0 ? 'Requires attention!' : 'All plants up to date',
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.danger,
        iconBgColor: AppColors.dangerLight,
        onTap: () => context.go(RouteNames.upcomingServices),
      ),
      DashboardStatCard(
        title: 'Completed Services',
        value: '${stats.completedServices}',
        subtitle: 'Historical records kept',
        icon: Icons.task_alt_rounded,
        iconColor: AppColors.accent,
        iconBgColor: AppColors.accentLight,
        onTap: () => context.go(RouteNames.completedServices),
      ),
      DashboardStatCard(
        title: 'Services This Month',
        value: '${stats.servicesDueThisMonth}',
        subtitle: 'Current monthly cycle',
        icon: Icons.calendar_month_rounded,
        iconColor: AppColors.warning,
        iconBgColor: AppColors.warningLight,
        onTap: () => context.go(RouteNames.upcomingServices),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    SizedBox(width: 175, child: cards[i]),
                  ],
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildServiceActivityCard(dynamic stats) {
    final Map<String, int> activity = stats.monthlyServiceActivity;
    final keys = activity.keys.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Service Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Maintenance and inspection volume across last 6 months',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Text('6-Month Trend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${keys[group.x]}: ${rod.toY.toInt()} services',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < keys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              keys[idx],
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(keys.length, (index) {
                  final val = (activity[keys[index]] ?? 0).toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val == 0 ? 0.3 : val,
                        color: index == keys.length - 1 ? AppColors.secondary : AppColors.primary,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantDistributionCard(dynamic stats) {
    final Map<String, int> distribution = stats.plantTypeDistribution;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plant Type Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Installed plant technology breakdown',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (distribution.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No plant installations registered yet.')),
            )
          else ...[
            ...distribution.entries.take(5).map((entry) {
              final total = stats.totalCustomers == 0 ? 1 : stats.totalCustomers;
              final percent = (entry.value / total);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value} plants (${(percent * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingScheduleCard(BuildContext context, dynamic stats) {
    final List upcoming = stats.upcomingSchedule;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Service Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.upcomingServices),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No upcoming services scheduled.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = upcoming[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.isOverdue
                          ? AppColors.dangerLight
                          : (s.isDueSoon ? AppColors.warningLight : AppColors.successLight),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      s.isOverdue
                          ? Icons.priority_high_rounded
                          : (s.isDueSoon ? Icons.access_time_rounded : Icons.calendar_today_rounded),
                      size: 16,
                      color: s.isOverdue
                          ? AppColors.danger
                          : (s.isDueSoon ? AppColors.warning : AppColors.success),
                    ),
                  ),
                  title: Text(
                    s.customerName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${s.siteName} • Service #${s.serviceNumber}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormatter.formatDate(s.serviceDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: s.isOverdue ? AppColors.danger : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormatter.formatRemainingDays(s.serviceDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: s.isOverdue
                              ? AppColors.danger
                              : (s.isDueSoon ? AppColors.warning : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentCustomersCard(BuildContext context, dynamic stats) {
    final List recent = stats.recentCustomers;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recently Added Customers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.customers),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No customers registered yet.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = recent[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondaryLight,
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${c.city.isNotEmpty ? c.city : 'Site'} • ${c.plantType}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    onPressed: () => context.go('/customers/${c.id}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
