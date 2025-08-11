import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auction_provider.dart';
import '../widgets/auction_card.dart';
import '../widgets/loading_widget.dart';
import 'auction_detail_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
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
    _loadAuctions();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Check for expired countdowns every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        final auctionProvider = context.read<AuctionProvider>();
        auctionProvider.refreshExpiredAuctions();
      }
    });
  }

  Future<void> _loadAuctions() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final auctionProvider = context.read<AuctionProvider>();
      await auctionProvider.refreshAllAuctions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load auctions: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
          child: Column(
            children: [
              _buildAppBar(context),
              _buildTabBar(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAuctionList('upcoming'),
                    _buildAuctionList('live'),
                    _buildAuctionList('completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.gavel,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Auction Hub',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Container(
              margin: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Live'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionList(String type) {
    return Consumer<AuctionProvider>(
      builder: (context, auctionProvider, child) {
        if (auctionProvider.isLoading && !_isRefreshing) {
          return const LoadingWidget(message: 'Loading auctions...');
        }

        List<dynamic> auctions = _getAuctionsByType(auctionProvider, type);

        if (auctions.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: _loadAuctions,
          color: Colors.blue,
          backgroundColor: Colors.white,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: auctions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final auction = auctions[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutBack,
                child: AuctionCard(
                  auction: auction,
                  onTap: () => _navigateToAuctionDetail(auction.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<dynamic> _getAuctionsByType(AuctionProvider provider, String type) {
    switch (type) {
      case 'upcoming':
        return provider.upcomingAuctions;
      case 'live':
        return provider.liveAuctions;
      case 'completed':
        return provider.completedAuctions;
      default:
        return [];
    }
  }

  Widget _buildEmptyState(String type) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Container(
                padding: const EdgeInsets.all(32),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      child: Icon(
                        _getEmptyStateIcon(type),
                        size: 48,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getEmptyStateTitle(type),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getEmptyStateSubtitle(type),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loadAuctions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.blue.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon(String type) {
    switch (type) {
      case 'upcoming':
        return Icons.schedule_rounded;
      case 'live':
        return Icons.live_tv_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.gavel_rounded;
    }
  }

  String _getEmptyStateTitle(String type) {
    switch (type) {
      case 'upcoming':
        return 'No Upcoming Auctions';
      case 'live':
        return 'No Live Auctions';
      case 'completed':
        return 'No Completed Auctions';
      default:
        return 'No Auctions';
    }
  }

  String _getEmptyStateSubtitle(String type) {
    switch (type) {
      case 'upcoming':
        return 'New auctions will appear here when they\'re scheduled';
      case 'live':
        return 'Active auctions will appear here when they go live';
      case 'completed':
        return 'Your auction history will appear here';
      default:
        return 'Check back later for new auctions';
    }
  }

  void _navigateToAuctionDetail(int auctionId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuctionDetailScreen(auctionId: auctionId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}