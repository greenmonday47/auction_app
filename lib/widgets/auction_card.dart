import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../utils/api_config.dart';
import 'countdown_timer.dart';

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback? onTap;
  final bool showStatus;

  const AuctionCard({
    super.key,
    required this.auction,
    this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[100]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with image and status
                Stack(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: auction.image != null && auction.image!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: auction.image!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.grey[100]!,
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                errorWidget: (context, url, error) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.grey[100]!,
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey[200]!,
                                      Colors.grey[100]!,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                            stops: const [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                    // Status badge
                    if (showStatus && !auction.isCurrentlyLive)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildStatusBadge(context),
                      ),
                    
                    // Live indicator
                    if (auction.isCurrentlyLive)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildLiveIndicator(context),
                      ),
                  ],
                ),
                
                // Content section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and description
                      Text(
                        auction.itemName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auction.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Current price section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Current',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auction.currentHighestBidFormatted ?? 
                              auction.startingPriceFormatted ?? 
                              'UGX ${auction.currentBid.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Bottom section with countdown and bid info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCountdownBackgroundColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getCountdownBorderColor(context),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Timer icon
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getCountdownIconBackgroundColor(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                auction.isCurrentlyLive ? Icons.timer_rounded : Icons.schedule_rounded,
                                color: _getCountdownIconColor(context),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Countdown text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auction.isCurrentlyLive ? 'Ends in' : 
                                    auction.isCompleted ? 'Auction Won' : 'Starts in',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getCountdownTextColor(context),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (auction.isCompleted) ...[
                                    Text(
                                      'Winner: ${_getWinnerName(auction)}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ] else ...[
                                    CountdownTimer(
                                      targetTime: auction.isCurrentlyLive ? auction.endTime : auction.startTime,
                                      isLive: auction.isCurrentlyLive,
                                      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getCountdownTextColor(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Bid count for live auctions
                            if (auction.isCurrentlyLive && auction.totalBids != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.gavel_rounded,
                                      size: 12,
                                      color: Colors.red[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${auction.totalBids}',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;
    
    if (auction.isCompleted) {
      badgeColor = Colors.green;
      statusText = 'DONE';
      statusIcon = Icons.check_circle_rounded;
    } else if (auction.isCurrentlyLive) {
      badgeColor = Colors.red;
      statusText = 'LIVE';
      statusIcon = Icons.live_tv_rounded;
    } else if (auction.isUpcoming) {
      badgeColor = Colors.blue;
      statusText = 'SOON';
      statusIcon = Icons.schedule_rounded;
    } else {
      badgeColor = Colors.grey;
      statusText = 'ENDED';
      statusIcon = Icons.stop_circle_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCountdownBackgroundColor(BuildContext context) {
    if (auction.isCurrentlyLive) {
      return Colors.red.withOpacity(0.05);
    } else if (auction.isUpcoming) {
      return Colors.blue.withOpacity(0.05);
    } else {
      return Colors.grey.withOpacity(0.05);
    }
  }

  Color _getCountdownBorderColor(BuildContext context) {
    if (auction.isCurrentlyLive) {
      return Colors.red.withOpacity(0.2);
    } else if (auction.isUpcoming) {
      return Colors.blue.withOpacity(0.2);
    } else {
      return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getCountdownIconBackgroundColor(BuildContext context) {
    if (auction.isCurrentlyLive) {
      return Colors.red.withOpacity(0.1);
    } else if (auction.isUpcoming) {
      return Colors.blue.withOpacity(0.1);
    } else {
      return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getCountdownIconColor(BuildContext context) {
    if (auction.isCurrentlyLive) {
      return Colors.red;
    } else if (auction.isUpcoming) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  Color _getCountdownTextColor(BuildContext context) {
    if (auction.isCurrentlyLive) {
      return Colors.red;
    } else if (auction.isUpcoming) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String _getWinnerName(Auction auction) {
    // For completed auctions, use winner name from API if available
    if (auction.isCompleted && auction.winnerName != null) {
      return _maskUserName(auction.winnerName!);
    }
    
    // Fallback to finding winner from bids if available
    if (auction.bids != null && auction.bids!.isNotEmpty) {
      final sortedBids = List<Bid>.from(auction.bids!);
      sortedBids.sort((a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0));
      final winner = sortedBids.first;
      return winner.userName ?? 'Anonymous';
    }
    
    return 'No bids';
  }

  String _maskUserName(String userName) {
    // Mask the last 2-3 characters with asterisks for privacy
    if (userName.length <= 3) {
      return '${userName[0]}***';
    } else {
      final visiblePart = userName.substring(0, userName.length - 2);
      return '$visiblePart**';
    }
  }
} 