
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Debounce search: wait 300ms after the user stops typing.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim().toLowerCase();

    // Clear search immediately when the input is empty.
    if (query.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = '';
        });
      }
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () {
        if (!mounted) return;

        if (_searchQuery != query) {
          setState(() {
            _searchQuery = query;
          });
        }
      },
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    final query = _searchQuery;

    if (query.isEmpty) return users;

    return users.where((user) {
      final username = user.username.trim().toLowerCase();
      final email = user.email.trim().toLowerCase();

      return username.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete user?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.deleteUser(user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddUserScreen(),
      ),
    );
  }

  void _editUser(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditUserScreen(user: user),
      ),
    );
  }

  void _viewDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(user: user),
      ),
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();

    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchQuery = '';
      });
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: 'Search by name or email...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Colors.indigo.shade400,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSearch,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.indigo.shade400,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final hasImage =
        user.imageUrl != null && user.imageUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _viewDetail(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.indigo.shade50,
                backgroundImage:
                    hasImage ? NetworkImage(user.imageUrl!) : null,
                child: !hasImage
                    ? Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.indigo.shade400,
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF20243A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.green.shade500,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'User account',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                tooltip: 'More actions',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey.shade600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editUser(user);
                  } else if (value == 'delete') {
                    _deleteUser(user);
                  } else if (value == 'detail') {
                    _viewDetail(user);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 19),
                        SizedBox(width: 10),
                        Text('View details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19),
                        SizedBox(width: 10),
                        Text('Edit user'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete user',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF20243A),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildEmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: 'Unable to load users: ${snapshot.error}',
            );
          }

          final users = snapshot.data ?? [];
          final filteredUsers = _filterUsers(users);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage your users',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF20243A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'View, search and manage user accounts.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: Colors.indigo,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL USERS',
                                style: TextStyle(
                                  color: Colors.indigo.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${users.length}',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF20243A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    _buildSearchField(),
                  ],
                ),
              ),

              Expanded(
                child: users.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No users found',
                        subtitle: 'Add a user to get started.',
                      )
                    : filteredUsers.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matching users',
                            subtitle:
                                'Try searching with another name or email.',
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(
                              20, 20, 20, 100,
                            ),
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'User list',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF20243A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${filteredUsers.length} users',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ...filteredUsers.map(_buildUserCard),
                            ],
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add User',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
