import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/nickname_screen.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/ranking/presentation/ranking_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/explore/presentation/spot_detail_screen.dart';
import '../../features/profile/presentation/my_map_screen.dart';
import '../../features/map/domain/spot_model.dart';
import '../../features/map/data/spots_repository.dart';
import '../services/supabase_service.dart';
import '../constants/app_colors.dart';

/// 앱 오픈 시 세션 기록 (하루 1회, ON CONFLICT DO NOTHING으로 중복 방지).
/// routerProvider와 분리하여 단일 책임 원칙 준수.
final _sessionRecorderProvider = Provider<void>((ref) {
  var sessionRecorded = false;
  ref.listen(authStateProvider, (_, next) {
    if (sessionRecorded) return;
    next.whenData((state) {
      if (state.session != null) {
        sessionRecorded = true;
        ref
            .read(supabaseClientProvider)
            .rpc('record_user_session')
            .catchError((_) => null);
      }
    });
  });
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  ref.onDispose(authNotifier.dispose);
  ref.listen(authStateProvider, (_, _) => authNotifier.value = !authNotifier.value);
  ref.listen(supabaseInitProvider, (_, _) => authNotifier.value = !authNotifier.value);

  // 세션 기록 — 별도 provider에서 처리
  ref.read(_sessionRecorderProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    // OAuth 콜백 URL 등 매핑 안 되는 경로: 에러 화면 대신 로딩 표시
    // (Supabase app_links 리스너가 인증 코드를 처리하면 자동으로 /map으로 이동)
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    redirect: (context, state) {
      final initAsync = ref.read(supabaseInitProvider);
      if (!initAsync.hasValue) return null; // Supabase 초기화 대기

      final session = ref.read(supabaseClientProvider).auth.currentSession;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;
      final isSplash    = loc == '/splash';
      final isOnboarding   = loc == '/onboarding';
      final isEmailAuth    = loc == '/email-auth';
      final isLoginCallback = loc.startsWith('/login-callback');

      if (!isLoggedIn) {
        // 미로그인: 스플래시/일반 → 온보딩으로 즉시 이동
        // login-callback은 Supabase가 처리 중이므로 그대로 둠
        if (isSplash || (!isOnboarding && !isEmailAuth && !isLoginCallback)) return '/onboarding';
        return null;
      }

      // 로그인 상태
      // 온보딩/이메일 화면에서 로그인 완료 → 닉네임 설정 없이 바로 맵
      if (isOnboarding || isEmailAuth) return '/map';
      // 스플래시: 2초 후 SplashScreen 자체가 /map 으로 이동
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        // GoRouter 전환 없음 — SplashScreen 내부에서 자체 페이드아웃 처리
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/nickname',
        name: 'nickname',
        builder: (context, state) => const NicknameScreen(),
      ),
      GoRoute(
        path: '/email-auth',
        name: 'email-auth',
        builder: (context, state) => const EmailAuthScreen(),
      ),
      // OAuth callback — Supabase processes the code via app_links listener.
      // GoRouter just needs a matching route to avoid GoException.
      GoRoute(
        path: '/login-callback',
        name: 'login-callback',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/explore',
            name: 'explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/ranking',
            name: 'ranking',
            builder: (context, state) => const RankingScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          // Sub-routes (no bottom nav)
          GoRoute(
            path: '/report',
            name: 'report',
            builder: (context, state) {
              final spotId = state.uri.queryParameters['spotId'];
              final spotName = state.uri.queryParameters['spotName'] ?? '';
              final placeId = state.uri.queryParameters['placeId'];
              final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
              final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
              return ReportScreen(
                spotId: spotId,
                spotName: spotName,
                placeId: placeId,
                lat: lat,
                lng: lng,
              );
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/my-map',
            name: 'my-map',
            builder: (context, state) => const MyMapScreen(),
          ),
          GoRoute(
            path: '/spot/:id',
            name: 'spot',
            builder: (context, state) {
              final spot = state.extra;
              if (spot is SpotModel) return SpotDetailScreen(spot: spot);
              // extra 없음 (딥링크/공유/앱 재시작) → DB에서 단건 조회
              return _SpotLoaderPage(spotId: state.pathParameters['id']!);
            },
          ),
        ],
      ),
    ],
  );
});

// ──────────────────────────────────────────────────────────────
// Main Shell — 4탭 하단 네비게이션 바
// ──────────────────────────────────────────────────────────────
class _MainShell extends StatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  static const _tabs = [
    _TabItem(path: '/map',     icon: Icons.map_outlined,         activeIcon: Icons.map,         label: '지도'),
    _TabItem(path: '/explore', icon: Icons.grid_view_outlined,   activeIcon: Icons.grid_view,   label: '탐색'),
    _TabItem(path: '/ranking', icon: Icons.bar_chart_outlined,   activeIcon: Icons.bar_chart,   label: '랭킹'),
    _TabItem(path: '/profile', icon: Icons.person_outline,       activeIcon: Icons.person,      label: '프로필'),
  ];

  // 서브 라우트에서는 바텀 네비 숨김
  static bool _showNav(String location) {
    return ['/map', '/explore', '/ranking', '/profile'].any(
      (p) => location == p || location.startsWith('$p?'),
    );
  }

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _overlayCtrl;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 ShellRoute 최초 진입은 항상 /map — 즉시 불투명으로 커버
    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );
    _scheduleFadeOut();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _overlayCtrl.dispose();
    super.dispose();
  }

  void _scheduleFadeOut() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _overlayCtrl.reverse();
    });
  }

  // 탭 버튼에서 직접 호출 — build() 밖이므로 notifyListeners 안전
  void _onTabTap(int i) {
    final path = _MainShell._tabs[i].path;
    final location = GoRouterState.of(context).matchedLocation;
    // 이미 같은 탭이면 오버레이/네비게이션 모두 생략 (깜박거림 방지)
    if (location == path || location.startsWith('$path?')) return;
    if (path == '/map') {
      _overlayCtrl.value = 1.0;
      _scheduleFadeOut();
    }
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (!_MainShell._showNav(location)) return widget.child;

    final currentIndex = _MainShell._tabs.indexWhere(
      (t) => location == t.path || location.startsWith('${t.path}?'),
    );
    final activeIndex = currentIndex < 0 ? 0 : currentIndex;

    return Scaffold(
      // 키보드 등장 시 탭 body 전체가 줄어들지 않도록 false 고정.
      // 각 하위 화면(ExploreScreen 등)이 자체 Scaffold에서 키보드를 처리한다.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          widget.child,
          // 지도탭 진입 시 플리커 방지 — 즉시 불투명, 부드럽게 페이드아웃
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _overlayCtrl,
              builder: (_, child) => Opacity(
                opacity: _overlayCtrl.value,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        activeIndex: activeIndex,
        tabs: _MainShell._tabs,
        onTap: _onTabTap,
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  final int activeIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.activeIndex, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: List.generate(tabs.length, (i) => Expanded(
          child: _AnimatedTabButton(
            tab: tabs[i],
            isActive: i == activeIndex,
            onTap: () => onTap(i),
          ),
        )),
      ),
    );
  }
}

class _AnimatedTabButton extends StatefulWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;
  const _AnimatedTabButton({required this.tab, required this.isActive, required this.onTap});

  @override
  State<_AnimatedTabButton> createState() => _AnimatedTabButtonState();
}

class _AnimatedTabButtonState extends State<_AnimatedTabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final activeColor = AppColors.mintGreen;
    final inactiveColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  key: ValueKey(isActive),
                  isActive ? widget.tab.activeIcon : widget.tab.icon,
                  size: 24,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? activeColor : inactiveColor,
                ),
                child: Text(widget.tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Spot Loader — 딥링크/공유 링크로 /spot/:id 진입 시 DB 조회
// ──────────────────────────────────────────────────────────────
class _SpotLoaderPage extends ConsumerWidget {
  final String spotId;
  const _SpotLoaderPage({required this.spotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<SpotModel?>(
      future: ref.read(spotsRepositoryProvider).fetchSpotById(spotId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final spot = snapshot.data;
        if (spot == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('카페 정보를 불러올 수 없습니다.')),
          );
        }
        return SpotDetailScreen(spot: spot);
      },
    );
  }
}
