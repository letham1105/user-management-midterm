
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  late final User? _currentUser;
  late Future<UserModel?> _profileFuture;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    _currentUser = FirebaseAuth.instance.currentUser;
    _loadProfile();
  }

  void _loadProfile() {
    if (_currentUser != null) {
      _profileFuture = _firestoreService.getUserProfile(
        _currentUser!.uid,
      );
    } else {
      _profileFuture = Future.value(null);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_currentUser == null || _isUploading) return;

    try {
      // 1. Chọn ảnh từ thư viện
      final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (selectedImage == null) return;

      setState(() {
        _isUploading = true;
      });

      // 2. Upload ảnh lên Cloudinary
      final String imageUrl =
          await _cloudinaryService.uploadImage(selectedImage);

      // 3. Lưu URL ảnh vào Firestore
      await _firestoreService.updateProfileImage(
        _currentUser!.uid,
        imageUrl,
      );

      // 4. Tải lại thông tin profile
      if (!mounted) return;

      setState(() {
        _loadProfile();
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _manageUsers() {
    Navigator.pushNamed(context, '/user_list');
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _authService.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: FutureBuilder<UserModel?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load profile: ${snapshot.error}',
              ),
            );
          }

          final profile = snapshot.data;

          final String username =
              profile?.username.isNotEmpty == true
                  ? profile!.username
                  : (_currentUser?.email?.split('@').first ?? 'User');

          final String email =
              _currentUser?.email ?? profile?.email ?? '';

          final String? imageUrl = profile?.imageUrl;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                ),
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar có thể nhấn để upload ảnh
                        GestureDetector(
                          onTap: _isUploading
                              ? null
                              : _pickAndUploadImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage:
                                    imageUrl != null &&
                                            imageUrl.isNotEmpty
                                        ? NetworkImage(imageUrl)
                                        : null,
                                child: imageUrl == null ||
                                        imageUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 65,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),

                              if (_isUploading)
                                const CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Color(0x99000000),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),

                              if (!_isUploading)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.blue,
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Tap avatar to change photo',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Chip(
                          avatar: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 18,
                          ),
                          label: Text(
                            isAdmin ? 'Administrator' : 'User',
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (isAdmin)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _manageUsers,
                              icon: const Icon(Icons.people),
                              label: const Text('Manage Users'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
