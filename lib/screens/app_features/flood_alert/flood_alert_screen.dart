import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/ai_triage_service.dart';
import '../../../features/rain_forecast/repository/weather_repository.dart';
import '../../../features/rain_forecast/models/weather_data_models.dart';
import '../../../features/rain_forecast/types.dart';
import '../rain_forecast/rain_forecast_screen.dart';

// ============================================================
// FLOOD COLORS
// ============================================================

class FloodColors {
  static Color get heritagePurple => AppColors.heritagePurple;
  static Color get riverFlow => AppColors.riverFlow;
  static Color get deepAnchor => AppColors.deepAnchor;

  // These are getters because the AppColors values may not be const.
  static Color get warmHearth => AppColors.warmHearth;
  static Color get cardWhite => AppColors.cardWhite;

  // Philippine blue fallback.
  // This avoids depending on AppColors.philippineBlue,
  // which does not exist in the current AppColors class.
  static const Color philippineBlue = Color(0xFF0056A3);

  // Flood severity colors.
  static const Color safe = Color(0xFF22C55E);
  static const Color alert = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color severe = Color(0xFF991B1B);

  static const Color safeBg = Color(0xFFF0FDF4);
  static const Color alertBg = Color(0xFFFFFBEB);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color severeBg = Color(0xFFFEE2E2);

  static LinearGradient get headerGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        heritagePurple,
        deepAnchor,
      ],
    );
  }

  static const LinearGradient safeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF16A34A),
      Color(0xFF22C55E),
    ],
  );
}

// ============================================================
// SCREEN
// ============================================================

class FloodAlertScreen extends StatefulWidget {
  const FloodAlertScreen({super.key});

  @override
  State<FloodAlertScreen> createState() => _FloodAlertScreenState();
}

class _FloodAlertScreenState extends State<FloodAlertScreen> {
  // ==========================================================
  // STATE
  // ==========================================================

  bool _isDark = false;

  AppColorScheme get _colors => AppColors.of(context);

  Color get _scaffoldBg {
    return _isDark ? AppColors.dark.background : AppColors.warmHearth;
  }

  Color get _cardBg {
    return _isDark ? AppColors.dark.cardSurface : AppColors.cardWhite;
  }

  Color get _titleText => _colors.textPrimary;

  Color get _bodyText => _colors.textSecondary;

  Color get _mutedText => _colors.textMuted;

  // ==========================================================
  // SERVICES
  // ==========================================================

  final RefreshController _refreshController = RefreshController();

  final AiTriageService _ai = AiTriageService();

  final WeatherRepository _weatherRepo = const WeatherRepository();

  // ==========================================================
  // LIVE RAIN RISK
  // ==========================================================

  RainRiskResult? _rainRisk;

  bool _isLoadingRainRisk = true;

  // ==========================================================
  // 7-DAY FORECAST
  // ==========================================================

  WeatherForecastData? _forecast;

  bool _isLoadingForecast = true;

  // ==========================================================
  // MOCK STATION / SAFETY DATA
  // ==========================================================
  //
  // IMPORTANT:
  // These are UI placeholder records.
  // They are NOT real river-gauge measurements.
  //

  late List<Map<String, dynamic>> _alerts;

  late List<Map<String, dynamic>> _safetyTips;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _initMockData();

    _fetchRainRisk();

    _fetchForecast();
  }

  // ==========================================================
  // FETCH RAIN RISK
  // ==========================================================

  Future<void> _fetchRainRisk() async {
    if (mounted) {
      setState(() {
        _isLoadingRainRisk = true;
      });
    }

    try {
      final result = await _ai.getRainRisk();

      if (!mounted) {
        return;
      }

      setState(() {
        _rainRisk = result;
        _isLoadingRainRisk = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _rainRisk = null;
        _isLoadingRainRisk = false;
      });
    }
  }

  // ==========================================================
  // FETCH 7-DAY FORECAST
  // ==========================================================

  Future<void> _fetchForecast() async {
    if (mounted) {
      setState(() {
        _isLoadingForecast = true;
      });
    }

    try {
      final data = await _weatherRepo.fetchForecast(assignedLocation);

      if (!mounted) {
        return;
      }

      setState(() {
        _forecast = data;
        _isLoadingForecast = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _forecast = null;
        _isLoadingForecast = false;
      });
    }
  }

  // ==========================================================
  // MOCK DATA
  // ==========================================================

  void _initMockData() {
    _alerts = [
      {
        'title': 'Bicol River Monitoring',
        'level': 'Normal',
        'color': FloodColors.safe,
        'bgColor': FloodColors.safeBg,
        'icon': Icons.waves_rounded,
        'updated': '30 minutes ago',
        'station': 'Station 1 - Poblacion',
      },
      {
        'title': 'Milaor Creek',
        'level': 'Normal',
        'color': FloodColors.safe,
        'bgColor': FloodColors.safeBg,
        'icon': Icons.water_drop_rounded,
        'updated': '1 hour ago',
        'station': 'Station 2 - San Roque',
      },
      {
        'title': 'San Francisco River',
        'level': 'Alert',
        'color': FloodColors.alert,
        'bgColor': FloodColors.alertBg,
        'icon': Icons.warning_rounded,
        'updated': '2 hours ago',
        'station': 'Station 3 - Capucnasan',
      },
    ];

    _safetyTips = [
      {
        'title': 'During Flood Warnings',
        'icon': Icons.shield_rounded,
        'tips': [
          'Move to higher ground immediately.',
          'Avoid walking or driving through flood waters.',
          'Stay tuned to local news for updates.',
          'Prepare an emergency kit with food, water, and medicines.',
        ],
      },
      {
        'title': 'Emergency Contacts',
        'icon': Icons.contact_phone_rounded,
        'tips': [
          'MDRRMO: (054) 123-4567',
          'Emergency Hotline: 911',
          'Barangay Hall: (054) 123-4568',
          'Rescue Team: 0912-345-6789',
        ],
      },
      {
        'title': 'Evacuation Routes',
        'icon': Icons.map_rounded,
        'tips': [
          'Milaor Central School - Primary evacuation center',
          'Barangay San Roque Covered Court',
          'Milaor Municipal Hall - Command center',
          'Follow designated routes posted in your barangay.',
        ],
      },
    ];
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _refreshController.dispose();

    super.dispose();
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _onRefresh() async {
    try {
      await Future.wait([
        _fetchRainRisk(),
        _fetchForecast(),
      ]);

      _refreshController.refreshCompleted();
    } catch (_) {
      _refreshController.refreshFailed();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                header: const WaterDropMaterialHeader(
                  backgroundColor: Color(0xFF4C229C),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    16.h,
                    20.w,
                    32.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroStatusCard(),
                      SizedBox(height: 20.h),
                      _buildRiverStationsSection(),
                      SizedBox(height: 20.h),
                      _buildActiveAdvisoriesSection(),
                      SizedBox(height: 20.h),
                      _buildRainOutlookSection(),
                      SizedBox(height: 20.h),
                      _buildSafetyTipsSection(),
                      SizedBox(height: 20.h),
                      _buildEmergencyActions(),
                      SizedBox(height: 20.h),
                      _buildAttributionCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        10.h,
        20.w,
        22.h,
      ),
      decoration: BoxDecoration(
        gradient: FloodColors.headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: FloodColors.deepAnchor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 34.h,
                decoration: BoxDecoration(
                  color: AppColors.philippineGold,
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FLOOD ALERT',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 2.6,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Milaor, Camarines Sur',
                      style: GoogleFonts.poppins(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Rain-risk monitoring and flood preparedness',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderAction(),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER ACTION
  // ==========================================================

  Widget _buildHeaderAction() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _outlineChip(
          Icons.refresh_rounded,
          'Refresh',
          onTap: () {
            _onRefresh();
          },
        ),
        SizedBox(width: 8.w),
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
          ),
          color: Colors.white,
          tooltip: 'Notifications',
          onPressed: () {
            _showMessage(
              context,
              'Alert notifications opened',
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // OUTLINE CHIP
  // ==========================================================

  Widget _outlineChip(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 9.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17.sp,
                color: Colors.white,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color _statusColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
      case 'normal':
        return FloodColors.safe;

      case 'moderate':
      case 'alert':
        return FloodColors.alert;

      case 'high':
        return FloodColors.danger;

      case 'severe':
        return FloodColors.severe;

      default:
        return FloodColors.heritagePurple;
    }
  }

  // ==========================================================
  // STATUS BACKGROUND
  // ==========================================================

  Color _statusBg(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
      case 'normal':
        return FloodColors.safeBg;

      case 'moderate':
      case 'alert':
        return FloodColors.alertBg;

      case 'high':
        return FloodColors.dangerBg;

      case 'severe':
        return FloodColors.severeBg;

      default:
        return FloodColors.heritagePurple.withValues(alpha: 0.1);
    }
  }

  // ==========================================================
  // STATUS ICON
  // ==========================================================

  IconData _statusIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
      case 'normal':
        return Icons.check_circle_rounded;

      case 'moderate':
      case 'alert':
        return Icons.warning_amber_rounded;

      case 'high':
        return Icons.dangerous_rounded;

      case 'severe':
        return Icons.report_rounded;

      default:
        return Icons.info_rounded;
    }
  }

  // ==========================================================
  // HERO STATUS CARD
  // ==========================================================

  Widget _buildHeroStatusCard() {
    // --------------------------------------------------------
    // LOADING
    // --------------------------------------------------------

    if (_isLoadingRainRisk) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
            color: _colors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.heritagePurple,
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text(
              'Checking live rain forecast…',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: _mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // --------------------------------------------------------
    // UNAVAILABLE
    // --------------------------------------------------------

    final rainRisk = _rainRisk;

    if (rainRisk == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
            color: _colors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48.sp,
              color: _mutedText,
            ),
            SizedBox(height: 16.h),
            Text(
              'Live rain forecast unavailable right now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: _titleText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Make sure the triage API is running and '
              'OPENWEATHER_API_KEY is configured.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: _mutedText,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18.h),
            OutlinedButton.icon(
              onPressed: _fetchRainRisk,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // --------------------------------------------------------
    // DATA
    // --------------------------------------------------------

    final statusText = rainRisk.floodRisk;

    final statusColor = _statusColor(statusText);

    final statusIcon = _statusIcon(statusText);

    final isSevere = statusText.toLowerCase() == 'high' ||
        statusText.toLowerCase() == 'severe';

    final rainMm = rainRisk.expectedRainMmNext12h;

    final progress = (rainMm / 50).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(
          color: _colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATUS BADGE
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      statusText.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Text(
            'Current flood-risk status',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: _mutedText,
            ),
          ),

          SizedBox(height: 22.h),

          // MAIN RAIN METRIC
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rainMm.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w900,
                  color: _titleText,
                  height: 1,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'mm',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _mutedText,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(
                    statusText,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'next 12h',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // RAIN PROGRESS
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: _colors.border.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(
                statusColor,
              ),
            ),
          ),

          SizedBox(height: 6.h),

          Text(
            'Rain accumulation vs severe threshold (50 mm)',
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: _mutedText,
            ),
          ),

          SizedBox(height: 22.h),

          // RECOMMENDED ACTION
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended action',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        rainRisk.recommendedAction,
                        style: GoogleFonts.inter(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                          color: _titleText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // SEVERE ADVISORY
          if (isSevere) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: FloodColors.severeBg,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: FloodColors.severe.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: FloodColors.severe,
                    size: 22.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evacuation advisory active',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: FloodColors.severe,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Prepare to move to higher ground. '
                          'Follow official MDRRMO instructions.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: _titleText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 500.ms,
        )
        .slideY(
          begin: 0.06,
          end: 0,
        );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: FloodColors.heritagePurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              size: 14.sp,
              color: FloodColors.heritagePurple,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: _titleText,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RIVER STATIONS
  // ==========================================================

  Widget _buildRiverStationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'River & Water Stations',
          Icons.water_drop_rounded,
        ),
        SizedBox(height: 12.h),
        ..._alerts.asMap().entries.map(
          (entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: 12.h,
              ),
              child: _buildStationCard(
                entry.value,
                entry.key,
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // STATION CARD
  // ==========================================================

  Widget _buildStationCard(
    Map<String, dynamic> station,
    int index,
  ) {
    final status = station['level'] as String? ?? 'Normal';

    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station['station'] as String? ?? 'Station',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: _titleText,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      station['title'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _buildStationMetric(
                Icons.info_outline_rounded,
                status,
                'Status',
              ),
              SizedBox(width: 24.w),
              _buildStationMetric(
                Icons.access_time_rounded,
                station['updated'] as String? ?? '—',
                'Updated',
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: (100 * index).ms,
        );
  }

  // ==========================================================
  // STATION METRIC
  // ==========================================================

  Widget _buildStationMetric(
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15.sp,
                color: _mutedText,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _titleText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE ADVISORIES
  // ==========================================================

  Widget _buildActiveAdvisoriesSection() {
    final active = _alerts
        .where(
          (alert) =>
              (alert['level'] as String? ?? '').toLowerCase() != 'normal',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Active Flood Advisories',
          Icons.notification_important_rounded,
        ),
        SizedBox(height: 12.h),
        if (active.isEmpty)
          _emptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No active advisories',
            subtitle:
                'No advisory is currently reported by the available monitoring data.',
          ),
        ...active.asMap().entries.map(
          (entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: 12.h,
              ),
              child: _buildAdvisoryCard(
                entry.value,
                entry.key,
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // ADVISORY CARD
  // ==========================================================

  Widget _buildAdvisoryCard(
    Map<String, dynamic> advisory,
    int index,
  ) {
    final status = advisory['level'] as String? ?? 'Normal';

    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14.w,
            height: 14.w,
            margin: EdgeInsets.only(top: 3.h),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advisory['title'] as String? ?? 'Advisory',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _titleText,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Station reports '
                  '${status.toLowerCase()} conditions — '
                  '${advisory['updated'] as String? ?? ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20.sp,
            color: _mutedText,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: (100 * index).ms,
        );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 40.h,
        horizontal: 20.w,
      ),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _colors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48.sp,
            color: _mutedText.withValues(alpha: 0.5),
          ),
          SizedBox(height: 14.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: _titleText,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5.sp,
              color: _mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RAIN OUTLOOK
  // ==========================================================

  Widget _buildRainOutlookSection() {
    final rainRisk = _rainRisk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          '7-Day Rain Outlook',
          Icons.water_drop_rounded,
        ),
        SizedBox(height: 12.h),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RainForecastScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: _colors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: FloodColors.philippineBlue.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          14.r,
                        ),
                      ),
                      child: Icon(
                        Icons.cloudy_snowing,
                        color: FloodColors.philippineBlue,
                        size: 26.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather Forecast',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: _titleText,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Open-Meteo • 7-day outlook',
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: _mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _mutedText,
                      size: 22.sp,
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // DESCRIPTION
                Text(
                  _isLoadingForecast
                      ? 'Loading the latest 7-day rainfall forecast…'
                      : _forecast == null
                          ? 'The 7-day rainfall forecast is unavailable right now.'
                          : 'Monitor rainfall conditions over the next 7 days to prepare for possible flooding.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    height: 1.55,
                    color: _forecast == null && !_isLoadingForecast
                        ? AppColors.error
                        : _bodyText,
                  ),
                ),

                SizedBox(height: 16.h),

                // STATUS
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: _forecast == null && !_isLoadingForecast
                        ? AppColors.error.withValues(
                            alpha: 0.08,
                          )
                        : FloodColors.philippineBlue.withValues(
                            alpha: 0.08,
                          ),
                    borderRadius: BorderRadius.circular(
                      12.r,
                    ),
                    border: Border.all(
                      color: _forecast == null && !_isLoadingForecast
                          ? AppColors.error.withValues(
                              alpha: 0.35,
                            )
                          : FloodColors.philippineBlue.withValues(
                              alpha: 0.25,
                            ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _forecast == null && !_isLoadingForecast
                            ? Icons.cloud_off_rounded
                            : Icons.info_outline_rounded,
                        color: _forecast == null && !_isLoadingForecast
                            ? AppColors.error
                            : FloodColors.philippineBlue,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _forecast == null && !_isLoadingForecast
                              ? 'Live forecast data is not available. '
                                  'Tap this card to open the detailed forecast.'
                              : 'Rainfall values are area-level estimates for '
                                  'Milaor, Camarines Sur and are not river-gauge measurements.',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            height: 1.5,
                            color: _forecast == null && !_isLoadingForecast
                                ? AppColors.error
                                : _bodyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // OPEN DETAILS BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RainForecastScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                    ),
                    label: const Text(
                      'View 7-Day Forecast',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FloodColors.heritagePurple,
                      side: BorderSide(
                        color: FloodColors.heritagePurple.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12.r,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(
              duration: 400.ms,
            )
            .slideY(
              begin: 0.04,
              end: 0,
            ),
      ],
    );
  }

  // ==========================================================
  // SAFETY TIPS
  // ==========================================================

  Widget _buildSafetyTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Safety Guidance',
          Icons.shield_rounded,
        ),
        SizedBox(height: 12.h),
        ..._safetyTips.asMap().entries.map(
          (entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: 12.h,
              ),
              child: _buildSafetyTipCard(
                entry.value,
                entry.key,
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // SAFETY TIP CARD
  // ==========================================================

  Widget _buildSafetyTipCard(
    Map<String, dynamic> tip,
    int index,
  ) {
    final List<dynamic> tips = (tip['tips'] as List<dynamic>?) ?? <dynamic>[];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety tip icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: FloodColors.heritagePurple.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              tip['icon'] is IconData
                  ? tip['icon'] as IconData
                  : Icons.info_rounded,
              color: FloodColors.heritagePurple,
              size: 20.sp,
            ),
          ),

          SizedBox(width: 12.w),

          // Safety tip content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title']?.toString() ?? 'Safety Tip',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _titleText,
                  ),
                ),

                SizedBox(height: 8.h),

                // Display each safety tip
                ...tips.map<Widget>((dynamic item) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: 7.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: 7.h,
                          ),
                          child: Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: BoxDecoration(
                              color: FloodColors.heritagePurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              color: _bodyText,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMERGENCY ACTIONS
  // ==========================================================

  Widget _buildEmergencyActions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepAnchor,
            AppColors.riverFlow,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepAnchor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMERGENCY ACTIONS',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(
                          alpha: 0.7,
                        ),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Need immediate help?',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildEmergencyActionButton(
                icon: Icons.phone_in_talk_rounded,
                label: 'Call Emergency',
                color: FloodColors.danger,
                onTap: () {
                  _showMessage(
                    context,
                    'Calling emergency hotline...',
                  );
                },
              ),
              SizedBox(width: 10.w),
              _buildEmergencyActionButton(
                icon: Icons.report_rounded,
                label: 'Report Flood',
                color: FloodColors.alert,
                onTap: () {
                  _showMessage(
                    context,
                    'Opening flood report form...',
                  );
                },
              ),
              SizedBox(width: 10.w),
              _buildEmergencyActionButton(
                icon: Icons.share_location_rounded,
                label: 'Share Location',
                color: FloodColors.philippineBlue,
                onTap: () {
                  _showMessage(
                    context,
                    'Sharing your location...',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(
          duration: 600.ms,
        );
  }

  // ==========================================================
  // EMERGENCY BUTTON
  // ==========================================================

  Widget _buildEmergencyActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 4.w,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(
                      14.r,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SAFETY MESSAGE
  // ==========================================================

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  // ==========================================================
  // ATTRIBUTION
  // ==========================================================

  Widget _buildAttributionCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.public_rounded,
                size: 14.sp,
                color: _mutedText,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Data source',
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _titleText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Weather data by Open-Meteo.com (CC BY 4.0). '
            'Flood advisories: monitor PAGASA and your local '
            'MDRRMO. Values are area-level grid-cell estimates '
            'for Milaor, Camarines Sur — not measurements taken '
            'inside a barangay.',
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              height: 1.55,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
