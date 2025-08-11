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

class _AuctionDetailScreenState extends State<AuctionDetailScreen> 
    with TickerProviderStateMixin {
  final _bidController = TextEditingController();
  bool _isPlacingBid = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
    _loadAuctionDetail();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _animationController.dispose();
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
        SnackBar(
          content: const Text('Please enter a valid bid amount'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
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
        SnackBar(
          content: const Text('Bid placed successfully!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      _bidController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auctionProvider.error ?? 'Failed to place bid'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50] ?? Colors.blue.shade50,
              Colors.white,
              Colors.blue[100] ?? Colors.blue.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuctionProvider>(
            builder: (context, auctionProvider, child) {
              final auction = auctionProvider.selectedAuction;
              
              if (auctionProvider.isLoading) {
                return const LoadingWidget(message: 'Loading auction details...');
              }

              if (auction == null) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Auction Not Found',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The auction you\'re looking for doesn\'t exist or has been removed.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    slivers: [
                      // Custom App Bar
                      SliverAppBar(
                        expandedHeight: 300,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            children: [
                              // Image
                              if (auction.image != null && auction.image!.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: auction.image!,
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) {
                                    return Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.grey[300]!,
                                            Colors.grey[200]!,
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.grey[300]!,
                                            Colors.grey[200]!,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey[300]!,
                                        Colors.grey[200]!,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              
                              // Gradient overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.5),
                                      ],
                                      stops: const [0.6, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Status chip (only show if not live)
                              if (!auction.isCurrentlyLive)
                                Positioned(
                                  top: 60,
                                  right: 16,
                                  child: _buildStatusChip(context, auction),
                                ),
                              
                                                             // Live indicator
                               if (auction.isCurrentlyLive)
                                 Positioned(
                                   top: 60,
                                   right: 16,
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                     decoration: BoxDecoration(
                                       color: Colors.red,
                                       borderRadius: BorderRadius.circular(20),
                                       boxShadow: [
                                         BoxShadow(
                                           color: Colors.red.withOpacity(0.3),
                                           blurRadius: 8,
                                           offset: const Offset(0, 2),
                                         ),
                                       ],
                                     ),
                                     child: Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Container(
                                           width: 8,
                                           height: 8,
                                           decoration: const BoxDecoration(
                                             color: Colors.white,
                                             shape: BoxShape.circle,
                                           ),
                                         ),
                                         const SizedBox(width: 6),
                                         const Text(
                                           'LIVE',
                                           style: TextStyle(
                                             color: Colors.white,
                                             fontWeight: FontWeight.bold,
                                             fontSize: 12,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               
                                                               // Countdown timer at bottom center of image
                                if (auction.isCurrentlyLive)
                                  Positioned(
                                    bottom: 20,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                                                                 child: CountdownTimer(
                                           targetTime: auction.endTime,
                                           isLive: true,
                                           textStyle: const TextStyle(
                                             color: Colors.red,
                                             fontWeight: FontWeight.w500,
                                             fontSize: 12,
                                           ),
                                         ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        leading: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.blue),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      
                      // Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and basic info
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      auction.itemName,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      auction.description,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                                                             // Bidding section for live auctions (moved up)
                               if (auction.isCurrentlyLive) ...[
                                 const SizedBox(height: 16),
                                 _buildBiddingSection(context, auction),
                                 const SizedBox(height: 16),
                               ],
                              
                              
                              
                              if (!auction.isCurrentlyLive && !auction.isCompleted) ...[
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 20,
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
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.schedule,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Upcoming Auction',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                Text(
                                                  'Starts in',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      CountdownTimer(
                                        targetTime: auction.startTime,
                                        isLive: false,
                                        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                                                             // Price information
                               _buildPriceSection(context, auction),
                               
                               // Winner section for completed auctions
                               if (auction.isCompleted) ...[
                                 const SizedBox(height: 16),
                                 _buildWinnerSection(context, auction),
                               ],
                               
                               // Time information section removed
                               
                               const SizedBox(height: 16),
                              
                              // Bid history
                              if (auction.bids != null && auction.bids!.isNotEmpty) ...[
                                _buildBidHistory(context, auction),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, Auction auction) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_money_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Price Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auction.startingPriceFormatted ?? 
                        'UGX ${auction.startingPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Bid',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCurrentBidFormatted(auction),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
    );
  }

  Widget _buildWinnerSection(BuildContext context, Auction auction) {
    // For completed auctions, use winnerId if available
    String? winnerName;
    double? winningAmount;
    
    if (auction.isCompleted && auction.winnerName != null) {
      winnerName = _maskUserName(auction.winnerName!);
      winningAmount = auction.finalBid ?? auction.startingPrice;
    } else if (auction.bids != null && auction.bids!.isNotEmpty) {
      // Fallback to finding winner from bids if available
      final sortedBids = List<Bid>.from(auction.bids!);
      sortedBids.sort((a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0));
      final winner = sortedBids.first;
      winnerName = winner.userName ?? 'Anonymous';
      winningAmount = winner.amount;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Auction Winner',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
                     const SizedBox(height: 20),
           if (winnerName != null) ...[
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.green[50],
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.green[200]!),
               ),
               child: Row(
                 children: [
                   Container(
                     width: 50,
                     height: 50,
                     decoration: BoxDecoration(
                       color: Colors.green[100],
                       borderRadius: BorderRadius.circular(25),
                     ),
                     child: Center(
                       child: Icon(
                         Icons.person,
                         color: Colors.green[700],
                         size: 24,
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           winnerName,
                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
                             fontWeight: FontWeight.bold,
                             color: Colors.grey[800],
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           'Final Bid: ${auction.finalBidFormatted ?? 'UGX ${winningAmount?.toStringAsFixed(0) ?? auction.startingPrice.toStringAsFixed(0)}'}',
                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                             color: Colors.green[700],
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                       ],
                     ),
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: Colors.green,
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Text(
                       'WINNER',
                       style: TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 12,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
           ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'No bids were placed for this auction',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  

  Widget _buildBiddingSection(BuildContext context, Auction auction) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Place Your Bid',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bidController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Bid Amount (UGX)',
                    hintText: 'Enter your bid',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.attach_money_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300] ?? Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300] ?? Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPlacingBid ? null : _placeBid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.blue.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPlacingBid
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Bid',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100] ?? Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: Each bid costs 1 token',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidHistory(BuildContext context, Auction auction) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Bid History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auction.bids!.length,
            itemBuilder: (context, index) {
              final bid = auction.bids![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bid.amountFormatted ?? 'UGX ${bid.amount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bid.userName ?? 'Anonymous',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      bid.createdAtFormatted ?? _formatDateTime(DateTime.parse(bid.createdAt)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getCurrentBidFormatted(Auction auction) {
    // If there are bids, get the highest bid amount
    if (auction.bids != null && auction.bids!.isNotEmpty) {
      // Sort bids by amount in descending order and get the highest
      final sortedBids = List<Bid>.from(auction.bids!);
      sortedBids.sort((a, b) => b.amount.compareTo(a.amount));
      final highestBid = sortedBids.first;
      
      // Return formatted amount if available, otherwise format it
      return highestBid.amountFormatted ?? 'UGX ${highestBid.amount.toStringAsFixed(0)}';
    }
    
    // If no bids, return starting price
    return auction.startingPriceFormatted ?? 'UGX ${auction.startingPrice.toStringAsFixed(0)}';
  }

  String _maskUserName(String userName) {
    // Mask the last 2-3 characters with asterisks for privacy
    if (userName.length <= 8) {
      return '${userName[0]}***';
    } else {
      final visiblePart = userName.substring(0, userName.length - 8);
      return '$visiblePart*****';
    }
  }
} 