class ApiConfig {
  // Base URL for the API
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  static const String baseUrl = 'https://legal-pleasant-prawn.ngrok-free.app/auction/public';
  
  // Auth endpoints
  static const String register = '/api/register';
  static const String login = '/api/login';
  
  // Auction endpoints
  static const String upcomingAuctions = '/api/auctions/upcoming';
  static const String liveAuctions = '/api/auctions/live';
  static const String completedAuctions = '/api/auctions/completed';
  static const String auctionDetail = '/api/auctions'; // /{id}
  static const String placeBid = '/api/auctions'; // /{id}/bid
  
  // Wallet endpoints
  static const String wallet = '/api/wallet';
  static const String topUp = '/api/wallet/topup';
  static const String transactions = '/api/wallet/transactions';
  
  // Payment gateway endpoints
  static const String initializeTopUp = '/api/payment/initializeTopUp';
  static const String verifyPayment = '/api/payment/verify'; // /{transactionId}
  static const String paymentHistory = '/api/payment/getPaymentHistory';
  static const String walletStats = '/api/payment/getWalletStats';
  static const String checkPendingTransactions = '/api/cron/check-payments';
  
  // User endpoints
  static const String userProfile = '/api/user';
  static const String updateProfile = '/api/user/update';
  static const String bidHistory = '/api/user/bids';
  
  // Rules endpoint
  static const String rules = '/api/rules';
  
  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return baseUrl + endpoint;
  }
  
  // Helper method to get auction detail URL
  static String getAuctionDetailUrl(int auctionId) {
    return baseUrl + auctionDetail + '/$auctionId';
  }
  
  // Helper method to get place bid URL
  static String getPlaceBidUrl(int auctionId) {
    return baseUrl + placeBid + '/$auctionId/bid';
  }
  
  // Helper method to get payment verification URL
  static String getPaymentVerificationUrl(String transactionId) {
    return baseUrl + verifyPayment + '/$transactionId';
  }
} 