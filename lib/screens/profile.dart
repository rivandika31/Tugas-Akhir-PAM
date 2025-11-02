// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:aplikasi_chat/screens/login.dart';
import 'package:image_picker/image_picker.dart';  // Tambahkan import ini
import 'dart:io';  // Untuk File

class ProfilePage extends StatefulWidget {
  final String email;
  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? username;
  String? profileImageUrl;
  String? password;
  Database? _database;
  File? _selectedImage;  // Untuk menyimpan gambar yang dipilih sementara

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'users.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, email TEXT, password TEXT)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS user_profiles(id INTEGER PRIMARY KEY, email TEXT, username TEXT, profile_image TEXT, created_at TEXT)',
        );
      },
    );

    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_database == null) return;

    // Ambil data user dari tabel users
    final userResults = await _database!.query(
      'users',
      where: 'email = ?',
      whereArgs: [widget.email],
    );

    if (userResults.isNotEmpty) {
      password = userResults.first['password'] as String?;

      // Cek apakah profil user sudah ada
      final profileResults = await _database!.query(
        'user_profiles',
        where: 'email = ?',
        whereArgs: [widget.email],
      );

      if (profileResults.isEmpty) {
        await _database!.insert(
          'user_profiles',
          {
            'email': widget.email,
            'username': widget.email.split('@')[0],
            'profile_image': null,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final results = await _database!.query(
        'user_profiles',
        where: 'email = ?',
        whereArgs: [widget.email],
      );

      if (results.isNotEmpty) {
        setState(() {
          username = results.first['username'] as String?;
          profileImageUrl = results.first['profile_image'] as String?;
        });
      }
    }
  }

  Future<void> _updateProfile(String newUsername, String? imagePath) async {
    try {
      if (_database == null) return;

      // Coba update dulu
      final affectedRows = await _database!.update(
        'user_profiles',
        {
          'username': newUsername,
          'profile_image': imagePath,
        },
        where: 'email = ?',
        whereArgs: [widget.email],
      );

      if (affectedRows == 0) {
        // Jika tidak ada baris yang diupdate, lakukan insert
        await _database!.insert(
          'user_profiles',
          {
            'email': widget.email,
            'username': newUsername,
            'profile_image': imagePath,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      }

      // Refresh data dari database
      final updatedProfile = await _database!.query(
        'user_profiles',
        where: 'email = ?',
        whereArgs: [widget.email],
      );

      if (updatedProfile.isNotEmpty) {
        setState(() {
          username = updatedProfile.first['username'] as String?;
          profileImageUrl = updatedProfile.first['profile_image'] as String?;
          _selectedImage = imagePath != null ? File(imagePath) : null;
        });

        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image quality to 70%
        maxWidth: 1024, // Limit maximum width
        maxHeight: 1024, // Limit maximum height
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        // Verify that the file exists and is readable
        if (await imageFile.exists()) {
          setState(() {
            _selectedImage = imageFile;
          });
        } else {
          throw Exception('Selected image file does not exist');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.  context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[850]!, Colors.grey[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile image
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (profileImageUrl != null
                          ? FileImage(File(profileImageUrl!))
                          : null),
                  child: (_selectedImage == null && profileImageUrl == null)
                      ? const Icon(Icons.person, size: 60, color: Colors.white70)
                      : null,
                ),
                const SizedBox(height: 20),

                // Username
                Text(
                  username ?? 'Set your username',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Email
                Text(
                  widget.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Edit button
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final controller =
                            TextEditingController(text: username ?? '');
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text(
                                'Edit Profile',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Preview gambar
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: _selectedImage != null
                                          ? FileImage(_selectedImage!)
                                          : (profileImageUrl != null
                                              ? FileImage(File(profileImageUrl!))
                                              : null),
                                      child: (_selectedImage == null && profileImageUrl == null)
                                          ? const Icon(Icons.person, size: 40, color: Colors.white70)
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    // Tombol pilih gambar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await _pickImage(ImageSource.gallery);
                                            setStateDialog(() {});  // Update dialog
                                          },
                                          icon: const Icon(Icons.photo_library, color: Colors.black),
                                          label: const Text('Gallery', style: TextStyle(color: Colors.black)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await _pickImage(ImageSource.camera);
                                            setStateDialog(() {});  // Update dialog
                                          },
                                          icon: const Icon(Icons.camera_alt, color: Colors.black),
                                          label: const Text('Camera', style: TextStyle(color: Colors.black)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // TextField untuk username
                                    TextField(
                                      controller: controller,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        labelStyle: TextStyle(color: Colors.white70),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white38),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;  // Reset jika cancel
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (controller.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Username cannot be empty'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Simpan path gambar yang akan digunakan
                                    String? finalImagePath;
                                    if (_selectedImage != null) {
                                      finalImagePath = _selectedImage!.path;
                                    } else if (profileImageUrl != null) {
                                      finalImagePath = profileImageUrl;
                                    }

                                    // Tutup dialog terlebih dahulu
                                    Navigator.pop(context);

                                    // Update profile
                                    await _updateProfile(
                                      controller.text.trim(),
                                      finalImagePath,
                                    );
                                  },
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(color: Colors.blueAccent),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 10,
                    shadowColor: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 30),

                // Account info card
                Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: Colors.black,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        ListTile(
                          leading:
                              const Icon(Icons.email, color: Colors.white70),
                          title: const Text('Email',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(widget.email,
                              style: const TextStyle(color: Colors.white70)),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.lock, color: Colors.white70),
                          title: const Text('Password',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                            password != null
                                ? '*' * password!.length
                                : 'Not available',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.person, color: Colors.white70),
                          title: const Text('Username',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                            username ?? 'Not set',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _database?.query(
                            'user_profiles',
                            where: 'email = ?',
                            whereArgs: [widget.email],
                          ),
                          builder: (context, snapshot) {
                            final createdAt =
                                snapshot.data?.first['created_at'] as String?;
                            return ListTile(
                              leading: const Icon(Icons.calendar_today,
                                  color: Colors.white70),
                              title: const Text('Account Created',
                                  style: TextStyle(color: Colors.white)),
                              subtitle: Text(
                                _formatDate(createdAt),
                                style:
                                    const TextStyle(color: Colors.white70),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Logout Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to logout?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: Colors.red.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}