import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/auction_provider.dart';
import '../widgets/loading_widget.dart';
import '../utils/api_service.dart';
import '../models/payment.dart';
import '../models/bid.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingTransactions = false;
  bool _isLoadingBids = false;
  List<Payment> _transactions = [];
  List<Bid> _bids = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTransactions(),
      _loadBids(),
    ]);
  }

  Future<void> _loadTransactions() async {
    if (_isLoadingTransactions) return;

    setState(() {
      _isLoadingTransactions = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoadingTransactions = false;
        });
        return;
      }

      final response = await ApiService().getPaymentHistory(authProvider.token!);
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _transactions = data.map((json) => Payment.fromJson(json)).toList();
          _isLoadingTransactions = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load transactions';
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading transactions: ${e.toString()}';
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _loadBids() async {
    if (_isLoadingBids) return;

    setState(() {
      _isLoadingBids = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoadingBids = false;
        });
        return;
      }

      final response = await ApiService().getBidHistory(authProvider.token!);
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _bids = data.map((json) => Bid.fromJson(json)).toList();
          _isLoadingBids = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load bids';
          _isLoadingBids = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading bids: ${e.toString()}';
        _isLoadingBids = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(
                  icon: Icon(Icons.payment),
                  text: 'Transactions',
                ),
                Tab(
                  icon: Icon(Icons.gavel),
                  text: 'Bids',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsTab(),
                _buildBidsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions) {
      return const LoadingWidget(message: 'Loading transactions...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(transaction.status),
                child: Icon(
                  _getStatusIcon(transaction.status),
                  color: Colors.white,
                ),
              ),
              title: Text(
                transaction.paymentType == 'topup' ? 'Wallet Top-up' : 'Payment',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: UGX ${transaction.amount.toStringAsFixed(0)}'),
                  Text('Tokens: ${transaction.tokens}'),
                  Text('Status: ${_getStatusText(transaction.status)}'),
                  Text(
                    'Date: ${transaction.createdAt}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: transaction.transactionId != null
                  ? Text(
                      'ID: ${transaction.transactionId!.substring(0, 8)}...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBidsTab() {
    if (_isLoadingBids) {
      return const LoadingWidget(message: 'Loading bids...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBids,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bids yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBids,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bids.length,
        itemBuilder: (context, index) {
          final bid = _bids[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: const Icon(
                  Icons.gavel,
                  color: Colors.white,
                ),
              ),
                             title: Text(
                 'Auction #${bid.auctionId}',
                 style: const TextStyle(fontWeight: FontWeight.bold),
               ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bid Amount: UGX ${bid.amount.toStringAsFixed(0)}'),
                  Text('Tokens Used: ${bid.tokensUsed}'),
                                     Text(
                     'Date: ${bid.createdAt}',
                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
                   ),
                ],
              ),
                             trailing: null,
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
      case PaymentStatus.approved:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
      case PaymentStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
      case PaymentStatus.approved:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
      case PaymentStatus.rejected:
        return Icons.error;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return 'Success';
      case PaymentStatus.approved:
        return 'Approved';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.rejected:
        return 'Rejected';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 