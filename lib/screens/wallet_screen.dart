import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/transaction.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../widgets/loading_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _showTopUpForm = false;
  bool _isProcessingPayment = false;
  bool _isMonitoringPayment = false;
  Payment? _currentPayment;
  String? _phoneValidationMessage;
  String? _currentPaymentStatus;
  bool _showPaymentBottomSheet = false;
  bool _showRefillBottomSheet = false;
  Set<String> _expandedDateGroups = {};

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadUserPhone();
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    
    if (authProvider.token != null) {
      await walletProvider.refreshWallet(authProvider.token!);
    }
  }

  Future<void> _loadUserPhone() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      // Format phone number for display (remove 256 prefix if present)
      String displayPhone = authProvider.user!.phone;
      if (displayPhone.startsWith('256')) {
        displayPhone = '0' + displayPhone.substring(3);
      }
      _phoneController.text = displayPhone;
    }
  }

  void _validatePhoneNumber() {
    final phone = _phoneController.text.trim();
    setState(() {
      if (phone.isEmpty) {
        _phoneValidationMessage = null;
      } else if (phone.length < 10) {
        _phoneValidationMessage = 'Your number is less, please check again';
      } else if (phone.length > 10) {
        _phoneValidationMessage = 'Don\'t exceed 10 digits';
      } else if (!phone.startsWith('07')) {
        _phoneValidationMessage = 'Number must start with 07';
      } else {
        _phoneValidationMessage = null;
      }
    });
  }

  Future<void> _initializePayment() async {
    if (_amountController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both amount and phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate phone number format
    String phoneNumber = _phoneController.text.trim();
    if (!PaymentService.isValidPhoneNumber(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number (e.g., 0705721545)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum top-up amount is UGX 500'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
             // Initialize payment with backend
       final response = await PaymentService.initializeTopUp(
         userId: authProvider.user!.id,
         amount: amount,
         phoneNumber: _phoneController.text.trim(),
       );

      if (response.success && response.data != null) {
        setState(() {
          _currentPayment = response.data;
        });

        // Submit to GMPay
        await _submitToGMPay();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _submitToGMPay() async {
    if (_currentPayment == null) return;

    try {
      // Format phone number for GMPay
      final formattedPhone = PaymentService.formatPhoneForGMPay(_phoneController.text);
      
      final response = await PaymentService.submitToGMPay(
        msisdn: formattedPhone,
        amount: _currentPayment!.amount.toInt().toString(), // Convert to clean integer string
        transactionId: _currentPayment!.transactionId!,
      );

      if (response.success) {
        // Check if the transaction is already successful
        final gmpayData = response.data;
        final rawStatus = gmpayData?['status']?.toString().toLowerCase();
        final gmpayStatus = gmpayData?['gmpay_status']?.toString().toLowerCase();
        
        print('Immediate check - Raw status: $rawStatus, GMPay status: $gmpayStatus');
        
        if (gmpayData != null && (rawStatus == 'approved' || rawStatus == 'success' || gmpayStatus == 'success')) {
          // Transaction is already successful, credit tokens immediately
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment successful! ${_currentPayment!.tokens} tokens added to your wallet.'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Refresh wallet data
            await _loadWalletData();
            
            // Clear form
            _amountController.clear();
            _phoneController.clear();
            setState(() {
              _showTopUpForm = false;
              _currentPayment = null;
              _isMonitoringPayment = false;
              _showPaymentBottomSheet = false;
              _showRefillBottomSheet = false;
            });
          }
        } else {
          // Transaction is pending, show bottom sheet immediately
          if (mounted) {
            setState(() {
              _showPaymentBottomSheet = true;
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _monitorPaymentStatus() async {
    if (_currentPayment?.transactionId == null || _isMonitoringPayment) {
      print('Monitoring already in progress or no transaction ID. Skipping.');
      return;
    }

    print('Starting payment monitoring for transaction: ${_currentPayment!.transactionId}');
    setState(() {
      _isMonitoringPayment = true;
      _showPaymentBottomSheet = true;
    });

    // Monitor payment status for up to 5 attempts with 15-second intervals
    for (int i = 0; i < 5; i++) {
      print('Polling attempt ${i + 1}/5');
      await Future.delayed(const Duration(seconds: 15));
      
      try {
        final response = await PaymentService.verifyPayment(
          transactionId: _currentPayment!.transactionId!,
        );

        if (response.success && response.data != null) {
          final payment = response.data!;
          
          print('Payment status: ${payment.status.name}, isSuccess: ${payment.isSuccess}, isApproved: ${payment.isApproved}');
          
          // Update current payment status for UI
          setState(() {
            _currentPaymentStatus = payment.status.name;
          });
          
          // Simple check: only look for GMPay status
          final gmpayStatus = payment.gmpayStatus?.toLowerCase();
          print('GMPay status: $gmpayStatus');
          
          if (gmpayStatus == 'success') {
            print('Payment SUCCESS! Stopping monitoring immediately.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment successful! ${payment.tokens} tokens added to your wallet.'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Refresh wallet data
              await _loadWalletData();
              
              // Clear form and stop monitoring immediately
              _amountController.clear();
              _phoneController.clear();
              
              if (mounted) {
                setState(() {
                  _showTopUpForm = false;
                  _currentPayment = null;
                  _isMonitoringPayment = false;
                  _showPaymentBottomSheet = false;
                  _showRefillBottomSheet = false;
                });
              }
            }
            print('Monitoring stopped due to SUCCESS.');
            return; // Stop monitoring immediately
          } else if (gmpayStatus == 'failed') {
            print('Payment FAILED! Stopping monitoring immediately.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {
                _isMonitoringPayment = false;
                _showPaymentBottomSheet = false;
                _showRefillBottomSheet = false;
              });
            }
            print('Monitoring stopped due to FAILED.');
            return; // Stop monitoring immediately
          }
          // If still pending, continue monitoring
          print('Payment still pending, continuing to monitor...');
          
          // Safety check: if we've been polling for more than 2 attempts and GMPay status is success, force stop
          if (i > 1 && gmpayStatus == 'success') {
            print('Safety check: Payment appears approved but monitoring continues. Force stopping.');
            if (mounted) {
              setState(() {
                _showTopUpForm = false;
                _currentPayment = null;
                _isMonitoringPayment = false;
                _currentPaymentStatus = null;
                _showRefillBottomSheet = false;
              });
            }
            return;
          }
        }
      } catch (e) {
        print('Error monitoring payment: $e');
        // Don't stop monitoring on network errors, just continue
      }
    }

    // Timeout after 5 attempts (75 seconds total)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment monitoring timeout after 75 seconds. Please check your wallet for updates.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _isMonitoringPayment = false;
        _showPaymentBottomSheet = false;
        _showRefillBottomSheet = false;
      });
    }
    print('Monitoring stopped due to timeout.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return LoadingOverlay(
            isLoading: walletProvider.isLoading,
            message: 'Loading wallet...',
            child: RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         // Balance card
                     _buildBalanceCard(context, walletProvider),
                     
                     const SizedBox(height: 16),
                     
                     // Action buttons row
                     _buildActionButtonsRow(context),
                     
                     const SizedBox(height: 24),
                    
                    // Transactions section
                    
                    // Transactions section
                    _buildTransactionsSection(context, walletProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomSheet: _showPaymentBottomSheet ? _buildPaymentBottomSheet(context) : 
                   _showRefillBottomSheet ? _buildRefillBottomSheet(context) : null,
    );
  }



  Widget _buildBalanceCard(BuildContext context, WalletProvider walletProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Token Balance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your available tokens',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main balance display with equivalent amount chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${walletProvider.tokens}',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'tokens',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Equivalent amount chip on the right
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.currency_exchange,
                        color: Colors.white.withOpacity(0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'UGX ${walletProvider.equivalentAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Quick stats row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1 Token',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '= UGX 100',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Min Refill',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'UGX 500',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUpSection(BuildContext context, WalletProvider walletProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Refill Tokens',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _showTopUpForm ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _showTopUpForm = !_showTopUpForm;
                    });
                  },
                ),
              ],
            ),
            if (_showTopUpForm) ...[
              const SizedBox(height: 16),
                             TextFormField(
                 controller: _phoneController,
                 keyboardType: TextInputType.phone,
                 maxLength: 10,
                 decoration: InputDecoration(
                   labelText: 'Phone Number',
                   hintText: 'Enter phone number (e.g., 07XXXXXXXX)',
                   prefixIcon: const Icon(Icons.phone),
                   counterText: '', // Hide the default counter
                   errorText: _phoneValidationMessage,
                   errorStyle: TextStyle(
                     color: _phoneValidationMessage != null && _phoneValidationMessage!.contains('Don\'t exceed') 
                         ? Colors.red 
                         : Colors.orange,
                   ),
                 ),
               ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (UGX)',
                  hintText: 'Enter amount to top up (min: 500)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              
              const SizedBox(height: 16),
                             SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: (_isProcessingPayment || _phoneValidationMessage != null) ? null : _initializePayment,
                  child: _isProcessingPayment
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Processing...'),
                          ],
                        )
                      : const Text('Top Up Wallet'),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                                         Text(
                       '• Minimum top-up: UGX 500 (5 tokens)\n• 1 token = UGX 100\n• Payment via mobile money\n• Enter phone number as 07XXXXXXXX (exactly 10 digits)',
                       style: TextStyle(
                         fontSize: 12,
                         color: Colors.blue[600],
                       ),
                     ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Success icon and message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Transaction Initiated Successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You have successfully initiated the Refill.\nPlease check your phone and enter your Mobile Money PIN to approve the transaction.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction ID: ${_currentPayment?.transactionId ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount: UGX ${_currentPayment?.amount.toStringAsFixed(0) ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tokens: ${_currentPayment?.tokens ?? 0} tokens',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Dismiss button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showPaymentBottomSheet = false;
                  _isMonitoringPayment = false;
                  _currentPayment = null;
                  _showRefillBottomSheet = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Dismiss',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(BuildContext context, WalletProvider walletProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (walletProvider.transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildGroupedTransactions(context, walletProvider.transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTransactions(BuildContext context, List<Transaction> transactions) {
    // Group transactions by date
    Map<String, List<Transaction>> groupedTransactions = {};
    
    for (var transaction in transactions) {
      final date = DateTime.parse(transaction.createdAt);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }
    
    // Sort dates in descending order (most recent first)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return Column(
      children: sortedDates.map((dateKey) {
        final date = DateTime.parse(dateKey);
        final transactions = groupedTransactions[dateKey]!;
        final isExpanded = _expandedDateGroups.contains(dateKey);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              // Date header (expandable)
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedDateGroups.remove(dateKey);
                    } else {
                      _expandedDateGroups.add(dateKey);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(date),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${transactions.length} transaction${transactions.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Transactions list (only show if expanded)
              if (isExpanded)
                Column(
                  children: transactions.map((transaction) {
                    return _buildTransactionTile(context, transaction);
                  }).toList(),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Transaction transaction) {
    Color statusColor;
    IconData statusIcon;
    
    switch (transaction.status) {
      case TransactionStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TransactionStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case TransactionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(
          statusIcon,
          color: statusColor,
        ),
      ),
      title: Text(
        transaction.amountFormatted ?? 'UGX ${transaction.amount.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${transaction.tokens} tokens',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            Text(
              transaction.note!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            transaction.statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            transaction.createdAtFormatted ?? _formatDateTime(DateTime.parse(transaction.createdAt)),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showRefillBottomSheet = true;
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              'Refill Tokens',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _checkTransactionStatus,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text(
              'Check Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefillBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: const Color(0xFF667eea),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Refill Tokens',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showRefillBottomSheet = false;
                    _amountController.clear();
                    _phoneController.clear();
                    _phoneValidationMessage = null;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Phone number field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter phone number (e.g., 0705721545)',
              prefixIcon: const Icon(Icons.phone),
              counterText: '',
              errorText: _phoneValidationMessage,
              errorStyle: TextStyle(
                color: _phoneValidationMessage != null && _phoneValidationMessage!.contains('Don\'t exceed') 
                    ? Colors.red 
                    : Colors.orange,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Amount field
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (UGX)',
              hintText: 'Enter amount to refill (min: 500)',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isProcessingPayment || _phoneValidationMessage != null) ? null : _initializePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessingPayment
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    )
                  : const Text(
                      'Refill Tokens',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Information card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Minimum refill: UGX 500 (5 tokens)\n• 1 token = UGX 100\n• Payment via mobile money\n• Enter phone number as 07XXXXXXXX (exactly 10 digits)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckStatusButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _checkTransactionStatus,
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text(
          'Check Transaction Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _checkTransactionStatus() async {
    try {
      // Call the cron endpoint to check pending transactions
      final response = await PaymentService.checkPendingTransactions();
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction status checked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh wallet data to show updated tokens
        await _loadWalletData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check transaction status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as "Monday, January 15" or similar
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ];
      
      final dayName = days[date.weekday - 1];
      final monthName = months[date.month - 1];
      
      return '$dayName, $monthName ${date.day}';
    }
  }
} 