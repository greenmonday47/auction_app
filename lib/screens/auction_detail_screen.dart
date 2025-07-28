import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../providers/auction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/api_config.dart';
import '../widgets/loading_widget.dart';
import '../widgets/countdown_timer.dart';

class AuctionDetailScreen extends StatefulWidget {
  final int auctionId;

  const AuctionDetailScreen({
    super.key,
    required this.auctionId,
  });

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _bidController = TextEditingController();
  bool _isPlacingBid = false;

  @override
  void initState() {
    super.initState();
    _loadAuctionDetail();
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  Future<void> _loadAuctionDetail() async {
    final auctionProvider = context.read<AuctionProvider>();
    await auctionProvider.loadAuctionDetail(widget.auctionId);
  }

  Future<void> _placeBid() async {
    if (_bidController.text.isEmpty) return;

    final amount = double.tryParse(_bidController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid bid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingBid = true;
    });

    final authProvider = context.read<AuthProvider>();
    final auctionProvider = context.read<AuctionProvider>();
    final walletProvider = context.read<WalletProvider>();

    final success = await auctionProvider.placeBid(
      auctionId: widget.auctionId,
      amount: amount,
      token: authProvider.token!,
    );

    if (success && mounted) {
      // Refresh wallet to update token balance
      await walletProvider.loadWallet(authProvider.token!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _bidController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auctionProvider.error ?? 'Failed to place bid'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isPlacingBid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Details'),
      ),
      body: Consumer<AuctionProvider>(
        builder: (context, auctionProvider, child) {
          final auction = auctionProvider.selectedAuction;
          
          if (auctionProvider.isLoading) {
            return const LoadingWidget(message: 'Loading auction details...');
          }

          if (auction == null) {
            return const Center(
              child: Text('Auction not found'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                if (auction.image != null && auction.image!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: auction.image!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) {
                      print('Loading auction detail image: $url');
                      return Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      print('Error loading auction detail image: $url - $error');
                      return Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              auction.itemName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(context, auction),
                        ],
                      ),
                      
                      // Live countdown for live auctions
                      if (auction.isCurrentlyLive) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CountdownTimer(
                                  targetTime: auction.endTime,
                                  isLive: true,
                                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Upcoming countdown for upcoming auctions
                      if (!auction.isCurrentlyLive && !auction.isCompleted) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CountdownTimer(
                                  targetTime: auction.startTime,
                                  isLive: false,
                                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        auction.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Price information
                      _buildPriceSection(context, auction),
                      
                      const SizedBox(height: 24),
                      
                      // Time information
                      _buildTimeSection(context, auction),
                      
                      const SizedBox(height: 24),
                      
                      // Bidding section for live auctions
                      if (auction.isCurrentlyLive) ...[
                        _buildBiddingSection(context, auction),
                        const SizedBox(height: 24),
                      ],
                      
                      // Bid history
                      if (auction.bids != null && auction.bids!.isNotEmpty) ...[
                        _buildBidHistory(context, auction),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, Auction auction) {
    Color chipColor;
    String statusText;
    
    if (auction.isCompleted) {
      chipColor = Colors.green;
      statusText = 'Completed';
    } else if (auction.isCurrentlyLive) {
      chipColor = Colors.red;
      statusText = 'LIVE';
    } else if (auction.isUpcoming) {
      chipColor = Colors.blue;
      statusText = 'Upcoming';
    } else {
      chipColor = Colors.grey;
      statusText = 'Ended';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, Auction auction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        auction.startingPriceFormatted ?? 
                        'UGX ${auction.startingPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Current Bid',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        auction.currentHighestBidFormatted ?? 
                        'UGX ${auction.currentBid.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(BuildContext context, Auction auction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        auction.startTimeFormatted ?? 
                        _formatDateTime(auction.startTime),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (!auction.isCurrentlyLive && !auction.isCompleted) ...[
                        const SizedBox(height: 4),
                        CountdownTimer(
                          targetTime: auction.startTime,
                          isLive: false,
                          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'End Time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        auction.endTimeFormatted ?? 
                        _formatDateTime(auction.endTime),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (auction.isCurrentlyLive) ...[
                        const SizedBox(height: 4),
                        CountdownTimer(
                          targetTime: auction.endTime,
                          isLive: true,
                          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiddingSection(BuildContext context, Auction auction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Place Your Bid',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bid Amount (UGX)',
                      hintText: 'Enter your bid',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isPlacingBid ? null : _placeBid,
                  child: _isPlacingBid
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Bid'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Each bid costs 1 token',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidHistory(BuildContext context, Auction auction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bid History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: auction.bids!.length,
              itemBuilder: (context, index) {
                final bid = auction.bids![index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    bid.amountFormatted ?? 'UGX ${bid.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    bid.userName ?? 'Anonymous',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    bid.createdAtFormatted ?? _formatDateTime(DateTime.parse(bid.createdAt)),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 