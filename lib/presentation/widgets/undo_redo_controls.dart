import 'package:finwise/presentation/providers/undo_redo_provider.dart';
import 'package:finwise/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Floating Action Button for undo/redo operations
class UndoRedoFAB extends ConsumerWidget {
  final bool extended;

  const UndoRedoFAB({
    super.key,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final recentActions = ref.watch(recentUndoActionsProvider);

    if (!canUndo && !canRedo) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canRedo)
          FloatingActionButton.small(
            heroTag: 'redo',
            onPressed: () => ref.undo(),
            tooltip: 'Redo',
            child: const Icon(Icons.redo),
          ),
        if (canRedo) const SizedBox(height: 8),
        if (canUndo)
          FloatingActionButton.small(
            heroTag: 'undo',
            onPressed: () => ref.undo(),
            tooltip: recentActions.isNotEmpty ? 'Undo: ${recentActions.last.description}' : 'Undo',
            child: const Icon(Icons.undo),
          ),
        if (canUndo) const SizedBox(height: 8),
        if (extended && recentActions.isNotEmpty)
          _buildRecentActionsMenu(context, recentActions, ref),
      ],
    );
  }

  Widget _buildRecentActionsMenu(BuildContext context, List<UndoableAction> actions, WidgetRef ref) {
    return Card(
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.all(AppTheme.spacingSM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recent Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            ...actions.take(3).map((action) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                action.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for undo/redo operations
class UndoRedoBottomSheet extends ConsumerWidget {
  const UndoRedoBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const UndoRedoBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final recentActions = ref.watch(recentUndoActionsProvider);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Undo / Redo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // Undo/Redo buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canUndo ? () => ref.undo() : null,
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUndo ? null : Theme.of(context).disabledColor,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canRedo ? () => ref.redo() : null,
                  icon: const Icon(Icons.redo),
                  label: const Text('Redo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedo ? null : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ],
          ),

          if (recentActions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'Recent Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            ...recentActions.take(5).map((action) => ListTile(
              leading: Icon(
                action.actionType == 'expense' ? Icons.receipt : Icons.account_balance_wallet,
                size: 20,
              ),
              title: Text(action.description),
              subtitle: Text(
                _formatTimestamp(action.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
          ],

          const SizedBox(height: AppTheme.spacingLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(undoRedoProvider.notifier).clearHistory();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear History'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// App bar action for undo/redo
class UndoRedoAppBarAction extends ConsumerWidget {
  const UndoRedoAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);

    if (!canUndo && !canRedo) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'undo':
            ref.undo();
            break;
          case 'redo':
            ref.redo();
            break;
          case 'history':
            UndoRedoBottomSheet.show(context);
            break;
        }
      },
      itemBuilder: (context) => [
        if (canUndo)
          const PopupMenuItem<String>(
            value: 'undo',
            child: ListTile(
              leading: Icon(Icons.undo, size: 20),
              title: Text('Undo'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (canRedo)
          const PopupMenuItem<String>(
            value: 'redo',
            child: ListTile(
              leading: Icon(Icons.redo, size: 20),
              title: Text('Redo'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'history',
          child: ListTile(
            leading: Icon(Icons.history, size: 20),
            title: Text('History'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}

/// Extension to easily add undo/redo to any scaffold
extension UndoRedoScaffoldExtension on Widget {
  Widget withUndoRedoControls({
    bool showFAB = true,
    bool showAppBarAction = false,
  }) {
    return UndoRedoControlsWrapper(
      child: this,
      showFAB: showFAB,
      showAppBarAction: showAppBarAction,
    );
  }
}

/// Wrapper widget that adds undo/redo controls to any scaffold
class UndoRedoControlsWrapper extends ConsumerWidget {
  final Widget child;
  final bool showFAB;
  final bool showAppBarAction;

  const UndoRedoControlsWrapper({
    super.key,
    required this.child,
    this.showFAB = true,
    this.showAppBarAction = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);

    if (!canUndo && !canRedo) {
      return child;
    }

    return Stack(
      children: [
        child,
        if (showFAB)
          Positioned(
            bottom: 16,
            right: 16,
            child: UndoRedoFAB(),
          ),
      ],
    );
  }
}

