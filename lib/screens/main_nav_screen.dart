import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import 'explore_screen.dart';
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
    final isLandlord = auth.isLandlord;

    final List<Widget> pages = [
      const ExploreScreen(),
      const _FavoritesView(),
      if (isLandlord) const LandlordPortalScreen() else const TenantPortalScreen(),
      const _ProfileView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // If accessing Portal without being authenticated, prompt login
          if ((index == 2) && !auth.isAuthenticated) {
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
          BottomNavigationBarItem(
            icon: Icon(isLandlord ? Icons.dashboard_outlined : Icons.key_outlined),
            activeIcon: Icon(isLandlord ? Icons.dashboard_rounded : Icons.key_rounded),
            label: isLandlord ? 'Landlord' : 'My Rentals',
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
              const Text('Sign in to save properties to your wishlist', style: TextStyle(color: AppTheme.textMain, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
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
                    Icon(Icons.favorite_outline, size: 64, color: AppTheme.textDim.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text('No favorites yet', style: TextStyle(color: AppTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Tap the heart icon on any listing to save it here', style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
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

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: auth.isAuthenticated && user != null
            ? Column(
                children: [
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
                          backgroundColor: auth.isLandlord ? AppTheme.accentEmerald : AppTheme.primary,
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textMain)),
                              const SizedBox(height: 2),
                              Text('@${user.username}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (auth.isLandlord ? AppTheme.accentEmerald : AppTheme.primary).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  auth.isLandlord ? 'LANDLORD ACCOUNT' : 'TENANT ACCOUNT',
                                  style: TextStyle(
                                    color: auth.isLandlord ? AppTheme.accentEmerald : AppTheme.primaryLight,
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
                  const SizedBox(height: 24),

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
                        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                        const Divider(color: AppTheme.borderDark),
                        _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phoneNumber ?? 'Not provided'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: AppTheme.accentRose),
                      label: const Text('Sign Out', style: TextStyle(color: AppTheme.accentRose)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.accentRose),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await auth.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully')),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 72, color: AppTheme.textDim),
                      const SizedBox(height: 16),
                      const Text('Not Signed In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                      const SizedBox(height: 8),
                      const Text('Sign in to rent rooms, schedule visits, or list properties', style: TextStyle(color: AppTheme.textDim, fontSize: 13), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                        child: const Text('Sign In / Register'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryLight),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textMain, fontSize: 13)),
        ],
      ),
    );
  }
}
