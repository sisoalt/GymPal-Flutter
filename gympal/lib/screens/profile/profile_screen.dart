import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../providers/auth_provider.dart';
// ThemeProvider not referenced directly here; PreferencesScreen handles it.
import 'preferences_screen.dart';
import '../../data/models/user_model.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Profile",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4A90E2)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Photo / Avatar
            _buildProfileHeader(user, context),
            const SizedBox(height: 24),

            // Personal Information Card
            _buildSectionCard(
              context,
              title: "Personal Information",
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(context, "Username", user?.username ?? "N/A", Icons.account_circle),
                const Divider(height: 24),
                _buildInfoRow(context, "Full Name", user?.fullName ?? "N/A", Icons.badge),
                const Divider(height: 24),
                _buildInfoRow(context, "Age", "${user?.age ?? 'N/A'} years", Icons.cake),
                const Divider(height: 24),
                _buildInfoRow(context, "Gender", user?.gender ?? "N/A", Icons.wc),
              ],
            ),
            const SizedBox(height: 16),

            // Body Metrics Card
            _buildSectionCard(
              context,
              title: "Body Metrics",
              icon: Icons.monitor_weight_outlined,
              children: [
                _buildInfoRow(
                  context,
                  "Height",
                  user?.height != null ? "${user!.height!.toStringAsFixed(1)} cm" : "Not set",
                  Icons.height,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  "Weight",
                  user?.weight != null ? "${user!.weight!.toStringAsFixed(1)} kg" : "Not set",
                  Icons.monitor_weight,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  "BMI",
                  user?.bmi != null ? "${user!.bmi!.toStringAsFixed(1)} (${user.bmiCategory})" : "Not available",
                  Icons.analytics_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            

            // Settings Card (Preferences contains Dark Mode toggle)
            _buildSectionCard(
              context,
              title: "Settings",
              icon: Icons.settings_outlined,
              children: [
                _buildActionTile(context, "Preferences", Icons.tune, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen())); }),
                _buildActionTile(context, "Change Password", Icons.lock_outline, () { Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())); }),
              ],
            ),
            const SizedBox(height: 16),

            // Logout Button
            _buildLogoutButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
                backgroundImage: _buildProfileImageProvider(user),
                child: user?.profileImagePath == null
                    ? Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: () => _pickProfileImageWithContext(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.08 * 255).round()),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt, size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? "User",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "@${user?.username ?? 'username'}",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  // NOTE: We need a helper that has access to BuildContext. Since
  // _buildProfileHeader is called from build (where context is available),
  // we'll call this helper from there with the real context.
  Future<void> _pickProfileImageWithContext(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);

      if (kIsWeb) {
        // On web, we cannot rely on a local file path. Store as base64 string.
        final bytes = await picked.readAsBytes();
        final b64 = base64Encode(bytes);
        await auth.updateProfileImage(b64);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(picked.path);
        final savedPath = p.join(appDir.path, 'profile_images');
        final dir = Directory(savedPath);
        if (!await dir.exists()) await dir.create(recursive: true);

        final File newImage = await File(picked.path).copy(p.join(dir.path, fileName));
        await auth.updateProfileImage(newImage.path);
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update photo')),
        );
      }
    }
  }

  ImageProvider? _buildProfileImageProvider(UserModel? user) {
    if (user?.profileImagePath == null) return null;
    final path = user!.profileImagePath!;

    // Try to detect base64 (web) image; fall back to file path
    try {
      // Heuristic: very long strings are likely base64 data
      if (kIsWeb || path.length > 100) {
        final bytes = base64Decode(path);
        return MemoryImage(bytes);
      }
    } catch (_) {
      // ignore and fall back to FileImage
    }

    try {
      return FileImage(File(path));
    } catch (_) {
      return null;
    }
  }

  Widget _buildSectionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLogoutDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text("Logout", style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
}
