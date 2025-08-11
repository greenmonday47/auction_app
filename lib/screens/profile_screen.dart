import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      _nameController.text = authProvider.user!.name;
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name cannot be empty'),
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

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() {
        _isEditing = false;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to update profile'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.user == null) {
                      return const Center(
                        child: Text('User not found'),
                      );
                    }

                    return LoadingOverlay(
                      isLoading: authProvider.isLoading,
                      message: 'Updating profile...',
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile header
                            _buildProfileHeader(context, authProvider),
                            
                            const SizedBox(height: 24),
                            
                            // Profile information
                            _buildProfileInfo(context, authProvider),
                            
                            const SizedBox(height: 24),
                            
                            // Actions
                            _buildActions(context),
                          ],
                        ),
                      ),
                    );
                  },
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
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.blue,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
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
                    Icons.person_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Profile',
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
        if (_isEditing)
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.blue.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

     Widget _buildProfileHeader(BuildContext context, AuthProvider authProvider) {
     return FadeTransition(
       opacity: _fadeAnimation,
       child: SlideTransition(
         position: _slideAnimation,
         child: Container(
           width: double.infinity,
           padding: const EdgeInsets.all(24),
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
                       child: Stack(
              children: [
                // Main content centered
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          child: Text(
                            authProvider.user!.name.isNotEmpty 
                                ? authProvider.user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _isEditing
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: TextFormField(
                                controller: _nameController,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            )
                          : Text(
                              authProvider.user!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              authProvider.user!.phone,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button positioned in top right corner
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.orange[50] : Colors.blue[50],
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
                      icon: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        color: _isEditing ? Colors.orange : Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (!_isEditing) {
                            _loadUserProfile(); // Reset to original values
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
         ),
       ),
     );
   }

  Widget _buildProfileInfo(BuildContext context, AuthProvider authProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                             Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.blue[50],
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Icon(
                       Icons.info_rounded,
                       color: Colors.blue,
                       size: 24,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Text(
                     'Account Details',
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Colors.grey[800],
                       letterSpacing: -0.5,
                     ),
                   ),
                 ],
               ),
                             const SizedBox(height: 24),
               
               // Member since field (read-only)
               _buildInfoField(
                 label: 'Member Since',
                 icon: Icons.calendar_today_rounded,
                 value: _formatDate(authProvider.user!.createdAt),
                 enabled: false,
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? value,
    bool enabled = true,
    bool isEditable = false,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled ? Colors.blue[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.blue : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isEditable
                ? TextFormField(
                    controller: controller,
                    enabled: enabled,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      border: InputBorder.none,
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Text(
                    value ?? '',
                    style: TextStyle(
                      color: valueColor ?? Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
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
            children: [
              _buildActionTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Wallet',
                subtitle: 'Manage your tokens and balance',
                onTap: () => Navigator.of(context).pushNamed('/wallet'),
              ),
              _buildActionTile(
                icon: Icons.history_rounded,
                title: 'Bid History',
                subtitle: 'View your auction history',
                onTap: () => Navigator.of(context).pushNamed('/bid-history'),
              ),
              _buildActionTile(
                icon: Icons.rule_rounded,
                title: 'Auction Rules',
                subtitle: 'Learn about auction guidelines',
                onTap: () => Navigator.of(context).pushNamed('/rules'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildActionTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: _logout,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isDestructive ? Colors.red[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[100] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : Colors.grey[800],
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive ? Colors.red[600] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[100] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: isDestructive ? Colors.red : Colors.blue,
            size: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
} 