import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/activity_result.dart';
import '../providers/auth_provider.dart';
import '../widgets/activity_icon.dart';
import '../widgets/glass_card.dart';

/// History screen redesigned as a tab within the main home shell.
class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  final List<ActivityResult> _activities = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  final _scrollController = ScrollController();
  static const int _pageSize = 20;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadActivities();
      }
    }
  }

  Future<void> _loadActivities({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _page = 0;
        _activities.clear();
        _hasMore = true;
      }
    });

    try {
      final token = ref.read(authProvider).token;
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.get(
        '${AppConfig.serverUrl}/activities/history',
        queryParameters: {
          'offset': _page * _pageSize,
          'limit': _pageSize,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['activities'] as List<dynamic>)
          .map((json) =>
              ActivityResult.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _activities.addAll(items);
        _page++;
        _hasMore = items.length == _pageSize;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['detail'] as String? ??
            'Failed to load history';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load history';
        _isLoading = false;
      });
    }
  }

  List<ActivityResult> get _filteredActivities {
    if (_filter == 'All') return _activities;
    final now = DateTime.now();
    if (_filter == 'Today') {
      return _activities
          .where((a) =>
              a.timestamp.year == now.year &&
              a.timestamp.month == now.month &&
              a.timestamp.day == now.day)
          .toList();
    }
    if (_filter == 'This Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return _activities.where((a) => a.timestamp.isAfter(weekAgo)).toList();
    }
    return _activities;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Filter chips
                Row(
                  children: ['All', 'Today', 'This Week'].map((label) {
                    final isSelected = _filter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected
                                ? AppTheme.accent.withOpacity(0.15)
                                : AppTheme.cardColor.withOpacity(0.5),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accent.withOpacity(0.4)
                                  : AppTheme.borderColor,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadActivities(refresh: true),
              color: AppTheme.accent,
              backgroundColor: AppTheme.surface,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null && _activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.error.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _loadActivities(refresh: true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.accent.withOpacity(0.15),
                    border: Border.all(
                      color: AppTheme.accent.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredActivities;

    if (filtered.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 32,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No activity history yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start sensing to record activities',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<ActivityResult>>{};
    for (final activity in filtered) {
      final key = _dateGroupKey(activity.timestamp);
      grouped.putIfAbsent(key, () => []).add(activity);
    }

    final groups = grouped.entries.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: groups.length + (_hasMore && _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accent,
                ),
              ),
            ),
          );
        }

        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10, left: 4),
              child: Text(
                group.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTertiary,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Activity items
            ...group.value.map((activity) => _buildActivityItem(activity)),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(ActivityResult activity) {
    final gradient = AppTheme.gradientForCategory(activity.activity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enableBlur: false,
        child: Row(
          children: [
            // Colored vertical bar
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Activity icon
            ActivityIconSmall(activity: activity.activity, size: 32),
            const SizedBox(width: 14),

            // Name + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.activity,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(activity.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Confidence
            Text(
              '${(activity.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: gradient.first,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateGroupKey(DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(ts.year, ts.month, ts.day);

    if (date == today) return 'TODAY';
    if (date == today.subtract(const Duration(days: 1))) return 'YESTERDAY';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[ts.month - 1]} ${ts.day}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Legacy HistoryScreen wrapper (kept for backward compatibility if needed).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: HistoryTab());
  }
}
