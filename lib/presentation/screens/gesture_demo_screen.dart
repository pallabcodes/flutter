import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/ui/gestures/advanced_gesture_system.dart';
import '../core/ui/gestures/finwise_gesture_library.dart';
import '../core/ui/gestures/gesture_performance_optimizer.dart';

/// Comprehensive gesture demonstration screen
class GestureDemoScreen extends ConsumerStatefulWidget {
  const GestureDemoScreen({super.key});

  @override
  ConsumerState<GestureDemoScreen> createState() => _GestureDemoScreenState();
}

class _GestureDemoScreenState extends ConsumerState<GestureDemoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Demo state
  String _lastGesture = 'None';
  Offset _dragPosition = const Offset(200, 200);
  double _chartZoom = 1.0;
  int _selectedInvestment = 0;
  bool _isFavorited = false;

  final List<String> _investments = [
    'AAPL - Apple Inc.',
    'GOOGL - Alphabet Inc.',
    'MSFT - Microsoft Corp.',
    'TSLA - Tesla Inc.',
    'NVDA - NVIDIA Corp.',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start gesture performance monitoring
    ref.read(gesturePerformanceProvider).startMonitoring();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showPerformanceReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGestureStatus(),
            const SizedBox(height: 20),
            _buildSwipeableCreditCardDemo(),
            const SizedBox(height: 20),
            _buildInteractiveChartDemo(),
            const SizedBox(height: 20),
            _buildDraggableBudgetDemo(),
            const SizedBox(height: 20),
            _buildGestureInvestmentSelector(),
            const SizedBox(height: 20),
            _buildContextMenuDemo(),
            const SizedBox(height: 20),
            _buildPullToRefreshDemo(),
            const SizedBox(height: 20),
            _buildMultiTouchDemo(),
            const SizedBox(height: 20),
            _buildDoubleTapFavoriteDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gesture Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Last Gesture: $_lastGesture'),
          const SizedBox(height: 4),
          Text('Selected Investment: $_selectedInvestment'),
          const SizedBox(height: 4),
          Text('Chart Zoom: ${_chartZoom.toStringAsFixed(2)}x'),
          const SizedBox(height: 4),
          Text('Favorited: $_isFavorited'),
        ],
      ),
    );
  }

  Widget _buildSwipeableCreditCardDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Swipeable Credit Card',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Swipe left to delete, right to favorite, up for details, down for actions',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: FinWiseGestureLibrary.createSwipeableCreditCard(
            cardWidget: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•••• •••• •••• 1234',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'JOHN DOE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '12/28',
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(
                        Icons.credit_card,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            onCardTapped: () => _updateGestureStatus('Card Tapped'),
            onCardSwipedLeft: () => _updateGestureStatus('Card Deleted (Swipe Left)'),
            onCardSwipedRight: () => _updateGestureStatus('Card Favorited (Swipe Right)'),
            onCardSwipedUp: () => _updateGestureStatus('Card Details (Swipe Up)'),
            onCardSwipedDown: () => _updateGestureStatus('Card Actions (Swipe Down)'),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveChartDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Interactive Investment Chart',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Pinch to zoom, pan to scroll, tap data points',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: FinWiseGestureLibrary.createInteractiveInvestmentChart(
            chartData: LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(20, (index) {
                    return FlSpot(
                      index.toDouble(),
                      100 + (index % 5) * 10 + (index % 3) * 5.0,
                    );
                  }),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            onDataPointTapped: (index) => _updateGestureStatus('Chart Point $index Tapped'),
            onZoomChanged: (zoom) {
              setState(() => _chartZoom = zoom);
              _updateGestureStatus('Chart Zoom: ${zoom.toStringAsFixed(2)}x');
            },
            onPanChanged: (offset) => _updateGestureStatus('Chart Panned'),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableBudgetDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Draggable Budget Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Long press and drag categories to reorganize',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Stack(
            children: [
              FinWiseGestureLibrary.createDraggableBudgetCategory(
                categoryWidget: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        'Food',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                categoryId: 'food',
                getPosition: () => _dragPosition,
                onPositionChanged: (position) {
                  setState(() => _dragPosition = position);
                  _updateGestureStatus('Category Dragged to ${position.toString()}');
                },
                onDragStart: () => _updateGestureStatus('Category Drag Started'),
                onDragEnd: () => _updateGestureStatus('Category Drag Ended'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGestureInvestmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Gesture Investment Selector',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Swipe to select different investments',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: FinWiseGestureLibrary.createGestureInvestmentSelector(
            investments: _investments,
            selectedIndex: _selectedInvestment,
            onInvestmentSelected: (index) {
              setState(() => _selectedInvestment = index);
              _updateGestureStatus('Investment Selected: ${index}');
            },
            itemBuilder: (context, index) {
              final isSelected = index == _selectedInvestment;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _investments[index].split(' - ')[0],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _investments[_selectedInvestment],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildContextMenuDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Context Menu Demo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Long press for context menu options',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: FinWiseGestureLibrary.createFinancialContextMenu(
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_money, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Transaction',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            itemType: 'transaction',
            itemId: 'demo_transaction_123',
            menuActions: {
              'Edit': () => _updateGestureStatus('Transaction Edit Selected'),
              'Delete': () => _updateGestureStatus('Transaction Delete Selected'),
              'Duplicate': () => _updateGestureStatus('Transaction Duplicate Selected'),
              'Share': () => _updateGestureStatus('Transaction Share Selected'),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPullToRefreshDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Pull to Refresh Demo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Pull down to refresh transaction list',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: FinWiseGestureLibrary.createTransactionPullToRefresh(
            transactionList: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text('Transaction ${index + 1}'),
                  subtitle: Text('\$${(index + 1) * 25}.00'),
                  trailing: Text('${index + 1}h ago'),
                );
              },
            ),
            onRefresh: () async {
              _updateGestureStatus('Transactions Refreshed');
              await Future.delayed(const Duration(seconds: 2));
            },
            refreshIndicator: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade500,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Refreshing...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiTouchDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Multi-Touch Property View',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Use multiple fingers to zoom and rotate property images',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: FinWiseGestureLibrary.createMultiTouchPropertyView(
            propertyWidget: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Property Image'),
                  ],
                ),
              ),
            ),
            propertyImages: [
              'image1.jpg',
              'image2.jpg',
              'image3.jpg',
            ],
            onImageChanged: (index) => _updateGestureStatus('Image Changed to $index'),
            onZoomChanged: (zoom) => _updateGestureStatus('Zoom: ${zoom.toStringAsFixed(2)}x'),
            onRotationChanged: (rotation) => _updateGestureStatus('Rotation: ${rotation.toStringAsFixed(1)}°'),
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleTapFavoriteDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Double Tap Favorite',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Double tap to favorite/unfavorite items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: FinWiseGestureLibrary.createDoubleTapFavorite(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _isFavorited ? Colors.red.shade400 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFavorited ? 'Favorited' : 'Not Favorited',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            isFavorited: _isFavorited,
            onFavoriteToggle: () {
              setState(() => _isFavorited = !_isFavorited);
              _updateGestureStatus('Favorite Toggled: $_isFavorited');
              _animationController.forward(from: 0.0);
            },
          ),
        ),
      ],
    );
  }

  void _updateGestureStatus(String gesture) {
    setState(() => _lastGesture = gesture);

    // Monitor gesture performance
    ref.read(gesturePerformanceProvider).monitorGesture(
      gestureId: DateTime.now().millisecondsSinceEpoch.toString(),
      gestureType: 'demo_gesture',
      responseTime: const Duration(milliseconds: 50),
      wasSuccessful: true,
      metadata: {'gesture': gesture},
    );
  }

  void _showPerformanceReport() {
    final report = ref.read(gesturePerformanceProvider).lastReport;

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No performance report available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gesture Performance Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('Total Gestures: ${report.overallMetrics.totalGestures}'),
              Text('Average Response: ${report.overallMetrics.averageResponseTime.inMilliseconds}ms'),
              Text('Success Rate: ${(report.overallMetrics.successRate * 100).toFixed(1)}%'),
              const SizedBox(height: 16),
              Text(
                'Recommendations:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...report.recommendations.map((rec) => Text('• $rec')),
            ],
          ),
        );
      },
    );
  }
}
