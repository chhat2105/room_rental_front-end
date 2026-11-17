import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import 'admin_portal_screen.dart';
import 'explore_screen.dart';
import 'messages_screen.dart';
import 'tenant_portal_screen.dart';
import 'landlord_portal_screen.dart';
import 'auth_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final isLandlord = auth.isLandlord;

    Widget portalScreen;
    if (isAdmin) {
      portalScreen = const AdminPortalScreen();
    } else if (isLandlord) {
      portalScreen = const LandlordPortalScreen();
    } else {
      portalScreen = const TenantPortalScreen();
    }

    final List<Widget> pages = [
      const ExploreScreen(),
      const _FavoritesView(),
      const MessagesScreen(),
      portalScreen,
      const _ProfileView(),
    ];

    IconData portalIcon = Icons.key_outlined;
    IconData portalActiveIcon = Icons.key_rounded;
    String portalLabel = 'My Rentals';

    if (isAdmin) {
      portalIcon = Icons.admin_panel_settings_outlined;
      portalActiveIcon = Icons.admin_panel_settings_rounded;
      portalLabel = 'Admin';
    } else if (isLandlord) {
      portalIcon = Icons.dashboard_outlined;
      portalActiveIcon = Icons.dashboard_rounded;
      portalLabel = 'Landlord';
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if ((index == 2 || index == 3) && !auth.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(portalIcon),
            activeIcon: Icon(portalActiveIcon),
            label: portalLabel,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    final propProv = context.watch<PropertyProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Favorites')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border, size: 64, color: AppTheme.textDim),
              const SizedBox(height: 12),
              const Text(
                'Sign in to save properties to your wishlist',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Favorites')),
      body: RefreshIndicator(
        onRefresh: () => propProv.loadFavorites(),
        child: propProv.favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 64,
                      color: AppTheme.textDim.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No favorites yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap the heart icon on any listing to save it here',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: propProv.favorites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  return PropertyCard(property: propProv.favorites[idx]);
                },
              ),
      ),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  void _editServerUrl(BuildContext context) {
    final propProv = context.read<PropertyProvider>();
    final ctrl = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Configure Backend URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://localhost:1212',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('localhost:1212', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://localhost:1212',
                ),
                ActionChip(
                  label: const Text('localhost:8080', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://localhost:8080',
                ),
                ActionChip(
                  label: const Text('10.0.2.2:1212', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://10.0.2.2:1212',
                ),
                ActionChip(
                  label: const Text('10.0.2.2:8080', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://10.0.2.2:8080',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService().setCustomBaseUrl(null);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              propProv.init();
            },
            child: const Text('Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService().setCustomBaseUrl(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              propProv.init();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final propProv = context.read<PropertyProvider>();
    final user = auth.user;
    final profile = auth.profile;

    String roleLabel = 'TENANT ACCOUNT';
    Color roleColor = AppTheme.primaryLight;
    if (auth.isAdmin) {
      roleLabel = 'ADMIN ACCOUNT';
      roleColor = AppTheme.accentCyan;
    } else if (auth.isLandlord) {
      roleLabel = 'LANDLORD ACCOUNT';
      roleColor = AppTheme.accentEmerald;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => auth.loadProfile(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (auth.isAuthenticated && user != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: roleColor,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (profile != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${profile.activeRentals}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentEmerald,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Active Rentals',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${profile.completedRentals}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentCyan,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Completed Rentals',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // User contact info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    const Divider(color: AppTheme.borderDark),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phoneNumber ?? 'Not provided',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppTheme.accentRose),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.accentRose),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentRose),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await auth.logout();
                    await propProv.loadFavorites();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully')),
                      );
                    }
                  },
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 72,
                      color: AppTheme.textDim,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Not Signed In',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to rent rooms, schedule visits, or list properties',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Sign In / Register'),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryLight),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
