import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../sync/sync_bloc.dart';
import '../sync/sync_state.dart';

/// Real-time feedback on the Sync Engine state (Task 8 UI requirement).
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final info = _info(context, state);
        if (info == null) return const SizedBox.shrink();
        return Material(
          color: info.color,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                info.showSpinner
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(info.icon, size: 18, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    info.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _BannerInfo? _info(BuildContext context, SyncState state) {
    if (state is SyncSyncing) {
      return _BannerInfo(
        text: '${state.currentOperation} (${state.processed + 1}/${state.total})',
        color: Colors.blue.shade600,
        showSpinner: true,
        icon: Icons.sync,
      );
    }
    if (state is SyncErrorRetrying) {
      return _BannerInfo(
        text: state.message,
        color: Colors.orange.shade700,
        showSpinner: true,
        icon: Icons.refresh,
      );
    }
    if (state is SyncConflictDetected) {
      return _BannerInfo(
        text: state.message,
        color: Colors.deepPurple.shade400,
        icon: Icons.merge_type,
      );
    }
    if (state is SyncPausedBackoff) {
      return _BannerInfo(
        text: state.message,
        color: Colors.red.shade700,
        icon: Icons.pause_circle,
      );
    }
    if (state is SyncIdle && state.pending > 0) {
      return _BannerInfo(
        text: '${state.pending} operation(s) pending sync.',
        color: Colors.grey.shade700,
        icon: Icons.cloud_queue,
      );
    }
    return null;
  }
}

class _BannerInfo {
  final String text;
  final Color color;
  final bool showSpinner;
  final IconData icon;
  _BannerInfo({
    required this.text,
    required this.color,
    this.showSpinner = false,
    required this.icon,
  });
}
