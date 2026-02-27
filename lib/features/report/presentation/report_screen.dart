import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../map/domain/spot_model.dart';
import 'report_controller.dart';
import 'widgets/db_meter_widget.dart';
import 'widgets/privacy_notice_bar.dart';
import 'widgets/sticker_card_grid.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String? spotId;
  final String spotName;

  const ReportScreen({super.key, this.spotId, required this.spotName});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  void initState() {
    super.initState();
    // Set args into shared provider, then start measurement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(reportControllerProvider.notifier);
      notifier.initialize(spotId: widget.spotId ?? '');
      notifier.startMeasurement();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: Text(
          widget.spotName.isEmpty ? '소음 측정' : widget.spotName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Fixed privacy notice (always visible)
          const PrivacyNoticeBar(),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ReportState state) {
    return switch (state.phase) {
      ReportPhase.measuring || ReportPhase.stabilizing => _MeasuringView(
          currentDb: state.currentDb,
          isStabilizing: state.phase == ReportPhase.stabilizing,
        ),
      ReportPhase.stickerSelection => _StickerView(
          measuredDb: state.stableDb,
          onSelected: (sticker) async {
            final controller = ref.read(reportControllerProvider.notifier);

            final isNear = await controller.verifyProximity();
            if (!isNear && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.reportTooFar),
                  backgroundColor: AppColors.dbLoud,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            await controller.submitWithSticker(sticker);
          },
        ),
      ReportPhase.submitting => const Center(
          child: CircularProgressIndicator(color: AppColors.mintGreen),
        ),
      ReportPhase.done => _DoneView(onBack: () => context.pop()),
      ReportPhase.error => _ErrorView(
          message: state.errorMessage ?? '알 수 없는 오류가 발생했습니다.',
          onRetry: () =>
              ref.read(reportControllerProvider.notifier).startMeasurement(),
        ),
    };
  }
}

class _MeasuringView extends StatelessWidget {
  final double currentDb;
  final bool isStabilizing;
  const _MeasuringView({required this.currentDb, required this.isStabilizing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: DbMeterWidget(currentDb: currentDb, isStabilizing: isStabilizing),
      ),
    );
  }
}

class _StickerView extends StatelessWidget {
  final double measuredDb;
  final ValueChanged<StickerType> onSelected;
  const _StickerView({required this.measuredDb, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: StickerCardGrid(measuredDb: measuredDb, onSelected: onSelected),
    );
  }
}

class _DoneView extends StatelessWidget {
  final VoidCallback onBack;
  const _DoneView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.mintGreen)
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          Text(AppStrings.reportSuccess, style: Theme.of(context).textTheme.titleLarge)
              .animate()
              .fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onBack, child: const Text('지도로 돌아가기'))
              .animate()
              .fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.dbVeryLoud),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
