import 'package:flutter/material.dart';
import 'package:ecosort/models/user.dart';
import 'package:ecosort/models/kecamatan.dart';
import 'package:ecosort/screens/login_screen.dart';
import 'package:ecosort/services/auth_service.dart';
import 'package:ecosort/services/profile_service.dart';
import 'package:ecosort/services/kecamatan_service.dart';
import 'package:ecosort/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import the WasteDeposit class
import '../services/waste_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isInitialized = false;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();

  // Password controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Kecamatan related variables
  List<Kecamatan> _kecamatanList = [];
  Kecamatan? _selectedKecamatan;
  bool _isLoadingKecamatan = false;

  // Avatar related variables
  File? _selectedImage;
  bool _isUploadingAvatar = false;

  // Waste history related variables
  List<WasteDeposit> _wasteHistory = [];
  bool _isLoadingHistory = false;
  int _currentTab = 0; // 0 for profile, 1 for history
  int _calculatedPoints = 0;
  int _calculatedStreakDays = 0;

  // Cache variables
  bool _isProfileLoaded = false;
  DateTime? _lastProfileLoadTime;
  static const Duration _cacheDuration = Duration(
    minutes: 5,
  ); // Cache for 5 minutes

  // Flag to prevent multiple profile loads
  bool _isProfileLoading = false;

  @override
  void initState() {
    super.initState();
    print('Initializing Profile Screen');
    // Initialize flags
    _isInitialized = false;
    _isProfileLoaded = false;
    _isProfileLoading = false;
    // Add a small delay to ensure proper initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _isInitialized = true;
        print('Loading profile and kecamatan for the first time');
        _loadProfile();
        _loadKecamatan();
      } else {
        print(
          'Profile screen already initialized, skipping duplicate initialization',
        );
        // Still update the UI if we have cached data
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('Profile Screen didChangeDependencies called');
    // Reset initialization flag when dependencies change
    _isInitialized = false;
    print('Reset initialization flag due to dependency change');
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('Profile Screen didUpdateWidget called');
    // Reset initialization flag when widget is updated
    _isInitialized = false;
    print('Reset initialization flag');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
    print('Profile Screen disposed');
  }

  _loadProfile() async {
    // Check if we're already loading to prevent multiple simultaneous loads
    if (_isProfileLoading || (_isLoading && _user != null)) {
      print('Already loading profile, skipping duplicate request');
      return;
    }

    // Check if we have a cached profile and it's still valid
    if (_isProfileLoaded &&
        _lastProfileLoadTime != null &&
        DateTime.now().difference(_lastProfileLoadTime!) < _cacheDuration &&
        _user != null) {
      // Use cached data, only set loading to false
      print('Using cached profile data');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    print('Loading profile from API');
    setState(() {
      _isLoading = true;
      _isProfileLoading = true;
    });

    try {
      final profileService = ProfileService();
      final user = await profileService.getProfile();

      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
          _isProfileLoading = false;
          _isProfileLoaded = user != null;
          _lastProfileLoadTime = DateTime.now();
          _calculatedPoints = user?.totalPoints ?? 0;
          _calculatedStreakDays = user?.streakDays ?? 0;

          if (user != null) {
            _nameController.text = user.name;
            _addressController.text = user.address ?? '';
            _districtController.text = user.district ?? '';
          }
        });

        if (_wasteHistory.isEmpty && !_isLoadingHistory) {
          _loadWasteHistory();
        }

        // After loading the user, try to update the district display with kecamatan name if needed
        if (user != null) {
          // Check if the district is an ID rather than a name
          final districtValue = user.district;
          if (districtValue != null && int.tryParse(districtValue) != null) {
            // It's an ID, let's try to get the name
            final kecamatanName = await _getKecamatanNameById(districtValue);
            if (kecamatanName != null && mounted) {
              setState(() {
                _user = User(
                  id: user.id,
                  name: user.name,
                  email: user.email,
                  address: user.address,
                  district:
                      kecamatanName, // Update district to show the name instead of ID
                  totalPoints: user.totalPoints,
                  streakDays: user.streakDays,
                  avatarPath: user.avatarPath,
                  lastScanAt: user.lastScanAt,
                  role: user.role,
                  emailVerifiedAt: user.emailVerifiedAt,
                );
                _lastProfileLoadTime = DateTime.now(); // Update cache time
              });
            }
          }
        }

        print(
          'Profile loaded successfully - User: ${user?.name}, Avatar: ${user?.avatarPath}',
        );
      }
    } catch (e, stackTrace) {
      print('Error loading profile: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProfileLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  _loadKecamatan() async {
    // Check if we're already loading or have data to prevent multiple loads
    if (_isLoadingKecamatan || _kecamatanList.isNotEmpty) {
      print(
        'Skipping kecamatan load - already loading: $_isLoadingKecamatan, has data: ${_kecamatanList.isNotEmpty}',
      );
      return;
    }

    setState(() {
      _isLoadingKecamatan = true;
    });

    try {
      print('=== LOADING KECAMATAN DATA ===');

      final kecamatanService = KecamatanService();
      final kecamatanList = await kecamatanService.getKecamatan();

      print('Loaded ${kecamatanList.length} kecamatan items');
      if (kecamatanList.isNotEmpty) {
        print('First 3 kecamatan:');
        for (int i = 0; i < kecamatanList.length && i < 3; i++) {
          print('  ${i + 1}. ${kecamatanList[i].name}');
        }
      } else {
        print('WARNING: No kecamatan data loaded');
      }

      if (mounted) {
        setState(() {
          _kecamatanList = kecamatanList;
          _isLoadingKecamatan = false;

          // Set default selection only if user has a district
          if (_user != null && _user!.district != null) {
            final userDistrict = _user!.district!;
            print('User district: $userDistrict');
            try {
              _selectedKecamatan = _kecamatanList.firstWhere(
                (kecamatan) => kecamatan.name == userDistrict,
              );
              print('Matched kecamatan: ${_selectedKecamatan?.name}');
            } catch (e) {
              print(
                'No matching kecamatan found, keeping null for hint display',
              );
              _selectedKecamatan = null;
            }
          } else {
            print('No user district, keeping null for hint display');
            _selectedKecamatan = null;
          }
        });
      }
    } catch (e, stackTrace) {
      print('ERROR loading kecamatan: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingKecamatan = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load kecamatan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isUpdatingProfile = false;

  _updateProfile() async {
    // Check if we're already updating to prevent multiple updates
    if (_isUpdatingProfile) {
      print('Already updating profile, skipping duplicate request');
      return;
    }

    // Validate form
    if (_selectedKecamatan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a kecamatan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password confirmation if password is entered
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan konfirmasi password tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('=== UPDATING PROFILE ===');
    print('Name: ${_nameController.text}');
    print('Address: ${_addressController.text}');
    print(
      'Selected Kecamatan: ${_selectedKecamatan?.name} (ID: ${_selectedKecamatan?.id})',
    );
    if (_passwordController.text.isNotEmpty) {
      print('Password will be updated');
    }

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final profileService = ProfileService();
      final updatedUser = await profileService.updateProfile(
        name: _nameController.text,
        address: _addressController.text,
        district: _selectedKecamatan!.id, // Send the kecamatan ID, not name
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        confirmPassword: _passwordController.text.isNotEmpty
            ? _confirmPasswordController.text
            : null,
      );

      if (updatedUser != null) {
        // Check if the updated user has kecamatan ID instead of name, and try to convert it
        String? finalDistrictName = updatedUser.district;
        if (finalDistrictName != null &&
            int.tryParse(finalDistrictName) != null) {
          // It's an ID, let's try to get the name
          final kecamatanName = await _getKecamatanNameById(finalDistrictName);
          if (kecamatanName != null) {
            finalDistrictName = kecamatanName;
          }
        }

        setState(() {
          _user = User(
            id: updatedUser.id,
            name: updatedUser.name,
            email: updatedUser.email,
            address: updatedUser.address,
            district:
                finalDistrictName, // Use the name if available, otherwise the ID
            totalPoints: updatedUser.totalPoints,
            streakDays: updatedUser.streakDays,
            avatarPath: updatedUser.avatarPath,
            lastScanAt: updatedUser.lastScanAt,
            role: updatedUser.role,
            emailVerifiedAt: updatedUser.emailVerifiedAt,
          );
          _isEditing = false;
          _isUpdatingProfile = false;
          // Clear password fields
          _passwordController.clear();
          _confirmPasswordController.clear();

          // Clear the profile cache since profile data has been updated
          _isProfileLoaded = false;
          _lastProfileLoadTime = null;
          _isProfileLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isUpdatingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      setState(() {
        _isUpdatingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat memperbarui profil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isLoggingOut = false;

  void _recalculatePointsAndStreak() {
    final validatedDeposits = _wasteHistory
        .where((deposit) => deposit.isValidated)
        .toList();

    _calculatedPoints = validatedDeposits.length;

    if (validatedDeposits.isEmpty) {
      _calculatedStreakDays = 0;
      return;
    }

    final dates =
        validatedDeposits
            .map((deposit) => _parseDate(deposit.timestamp))
            .where((date) => date != null)
            .map((date) => DateTime(date!.year, date.month, date.day))
            .toSet()
            .toList()
          ..sort();

    if (dates.isEmpty) {
      _calculatedStreakDays = 0;
      return;
    }

    int streak = 1;
    DateTime currentDate = dates.last;

    for (int i = dates.length - 2; i >= 0; i--) {
      final date = dates[i];
      final difference = currentDate.difference(date).inDays;
      if (difference == 1) {
        streak += 1;
        currentDate = date;
      } else if (difference > 1) {
        break;
      }
    }

    _calculatedStreakDays = streak;
  }

  _logout() async {
    // Check if we're already logging out to prevent multiple logout attempts
    if (_isLoggingOut) {
      print('Already logging out, skipping duplicate request');
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final authService = AuthService();
      final result = await authService.logout();

      if (mounted) {
        // Show message based on result
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result.containsKey('warning')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['warning']),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Clear the profile cache on logout
        _isProfileLoaded = false;
        _lastProfileLoadTime = null;
        _isProfileLoading = false;
        _isLoggingOut = false;

        // Navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  _loadWasteHistory() async {
    // Check if we're already loading or have data to prevent multiple loads
    if (_isLoadingHistory || _wasteHistory.isNotEmpty) {
      print(
        'Skipping waste history load - already loading: $_isLoadingHistory, has data: ${_wasteHistory.isNotEmpty}',
      );
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi tidak valid, silakan login kembali'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String? userId = _user?.id;
      if (userId == null || userId.isEmpty) {
        final currentUser = await authService.getCurrentUser();
        userId = currentUser?.id;
        if (currentUser != null && _user == null && mounted) {
          setState(() {
            _user = currentUser;
          });
        }
      }

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tidak dapat menentukan pengguna. Silakan coba lagi.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final wasteService = WasteService();
      final history = await wasteService.getWasteHistory(
        token: token,
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _wasteHistory = history;
          _isLoadingHistory = false;
          _recalculatePointsAndStreak();
        });
        print('Loaded ${history.length} waste history items');
      }
    } catch (e) {
      print('Error loading waste history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat riwayat penyetoran'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isPickingImage = false;

  _pickImage() async {
    // Check if we're already picking an image to prevent multiple picks
    if (_isPickingImage) {
      print('Already picking image, skipping duplicate request');
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // Reduce image size to optimize upload
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isPickingImage = false;
        });

        // Upload the avatar after selecting
        await _uploadAvatar(_selectedImage!.path);
      } else {
        setState(() {
          _isPickingImage = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memilih gambar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  _uploadAvatar(String imagePath) async {
    if (_isUploadingAvatar) return; // Prevent multiple uploads

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final profileService = ProfileService();
      final updatedUser = await profileService.uploadAvatar(imagePath);

      if (updatedUser != null) {
        // Clear the profile cache to force reload with new avatar
        _isProfileLoaded = false;
        _lastProfileLoadTime = null;
        _isProfileLoading = false; // Reset loading flag

        // Update the user data directly to show the new avatar immediately
        if (mounted) {
          setState(() {
            _user = updatedUser;
            _isUploadingAvatar = false;
            // Keep other state consistent
            if (_user != null) {
              _nameController.text = updatedUser.name;
              _addressController.text = updatedUser.address ?? '';
              _districtController.text = updatedUser.district ?? '';
            }
          });

          // Resolve kecamatan ID to name (API returns ID, not name)
          final districtValue = updatedUser.district;
          if (districtValue != null && int.tryParse(districtValue) != null) {
            final kecamatanName = await _getKecamatanNameById(districtValue);
            if (kecamatanName != null && mounted) {
              setState(() {
                _user = User(
                  id: _user!.id,
                  name: _user!.name,
                  email: _user!.email,
                  address: _user!.address,
                  district: kecamatanName,
                  avatarPath: _user!.avatarPath,
                  totalPoints: _user!.totalPoints,
                  streakDays: _user!.streakDays,
                );
              });
            }
          }

          print('Avatar uploaded successfully and state updated directly');
          print('Updated user has district: ${_user?.district}');
          print('Updated user has avatarPath: ${updatedUser.avatarPath}');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar berhasil diunggah'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isUploadingAvatar = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunggah avatar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat mengunggah avatar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 260,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1B5E20),
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          left: -40,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        // Avatar and name
                        SafeArea(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 10),
                                _buildAvatarWidget(),
                                const SizedBox(height: 12),
                                Text(
                                  _user?.name ?? 'Pengguna',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (_isEditing && _currentTab == 0)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: TabBar(
                      labelColor: const Color(0xFF2E7D32),
                      unselectedLabelColor: Colors.grey[500],
                      indicatorColor: const Color(0xFF2E7D32),
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline_rounded, size: 20),
                              SizedBox(width: 6),
                              Text('Profil'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 20),
                              SizedBox(width: 6),
                              Text('Riwayat'),
                            ],
                          ),
                        ),
                      ],
                      onTap: (index) {
                        setState(() {
                          _currentTab = index;
                          if (index == 1 &&
                              (_wasteHistory.isEmpty || !_isLoadingHistory)) {
                            _loadWasteHistory();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [_buildProfileContent(), _buildHistoryContent()],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: _user?.avatarPath != null
                ? Image.network(
                    _buildAvatarUrl(_user!.avatarPath!),
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF43A047),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 45,
                          color: Colors.white,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFF43A047),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFF43A047),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploadingAvatar ? null : _pickImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isUploadingAvatar
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data pengguna',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        children: [
          if (!_isEditing) ...[
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Poin',
                    _calculatedPoints.toString(),
                    Icons.star_rounded,
                    const [Color(0xFFFFA726), Color(0xFFFF9800)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Streak',
                    '${_calculatedStreakDays} hari',
                    Icons.local_fire_department_rounded,
                    const [Color(0xFFEF5350), Color(0xFFE53935)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.email_outlined, 'Email', _user!.email),
                  _buildDivider(),
                  _buildInfoTile(
                    Icons.location_on_outlined,
                    'Alamat',
                    _user!.address ?? '-',
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    Icons.map_outlined,
                    'Kecamatan',
                    _user!.district ?? '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text(
                  'Edit Profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Keluar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[300]!, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Edit Mode
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Profil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF43A047),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Alamat',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF43A047),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingKecamatan
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32),
                          ),
                        )
                      : _kecamatanList.isEmpty
                      ? const Text('Data kecamatan tidak tersedia')
                      : DropdownButtonFormField<Kecamatan>(
                          value: _selectedKecamatan,
                          hint: const Text('Pilih Kecamatan Anda'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Kecamatan',
                            prefixIcon: const Icon(
                              Icons.map_outlined,
                              color: Color(0xFF43A047),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: _kecamatanList.map((kecamatan) {
                            return DropdownMenuItem<Kecamatan>(
                              value: kecamatan,
                              child: Text(
                                kecamatan.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (Kecamatan? newValue) {
                            setState(() {
                              _selectedKecamatan = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) return 'Silakan pilih kecamatan';
                            return null;
                          },
                          dropdownColor: Colors.white,
                          menuMaxHeight: 300,
                        ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Kosongkan jika tidak ingin mengubah password',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password Baru (Opsional)',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF43A047),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      prefixIcon: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF43A047),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (_passwordController.text.isNotEmpty &&
                          value != _passwordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _updateProfile,
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (_wasteHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 56,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada riwayat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai setor sampah untuk melihat riwayat',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _wasteHistory.length,
      itemBuilder: (context, index) {
        final deposit = _wasteHistory[index];
        final isOrganic = deposit.trashType.toLowerCase() == 'organik';
        final typeColor = isOrganic
            ? const Color(0xFF43A047)
            : const Color(0xFF1E88E5);
        final typeIcon = isOrganic
            ? Icons.eco_rounded
            : Icons.recycling_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Color accent strip
              Container(
                width: 5,
                height: 90,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Type icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTrashTypeDisplayName(deposit.trashType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${deposit.volumeLiters.toStringAsFixed(1)} L',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.scale_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${deposit.weightKg.toStringAsFixed(2)} Kg',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(deposit.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Status badge
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: deposit.isValidated
                        ? const Color(0xFF2E7D32).withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deposit.isValidated
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_top_rounded,
                        size: 14,
                        color: deposit.isValidated
                            ? const Color(0xFF2E7D32)
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deposit.isValidated ? 'Valid' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: deposit.isValidated
                              ? const Color(0xFF2E7D32)
                              : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTrashTypeDisplayName(String type) {
    final lowerType = type.toLowerCase();
    switch (lowerType) {
      case 'organik':
        return 'Sampah Organik';
      case 'plastik':
        return 'Plastik';
      case 'kertas':
        return 'Kertas';
      case 'residu':
        return 'Sampah Residu';
      default:
        return type;
    }
  }

  String _formatDate(String dateString) {
    // Format date string from ISO format to readable format
    final parsed = _parseDate(dateString);
    if (parsed == null) {
      return dateString;
    }
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF43A047), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getKecamatanNameById(String kecamatanId) async {
    // Check if we already have the kecamatan list loaded
    if (_kecamatanList.isNotEmpty) {
      final kecamatan = _kecamatanList.firstWhere(
        (element) => element.id == kecamatanId,
        orElse: () => Kecamatan(id: '', name: ''),
      );
      if (kecamatan.id.isNotEmpty) {
        return kecamatan.name;
      }
    }

    // If kecamatan list is empty or not found, fetch from service
    try {
      final kecamatanService = KecamatanService();
      final kecamatanList = await kecamatanService.getKecamatan();

      final kecamatan = kecamatanList.firstWhere(
        (element) => element.id == kecamatanId,
        orElse: () => Kecamatan(id: '', name: ''),
      );

      if (kecamatan.id.isNotEmpty) {
        // Update the local kecamatan list
        if (mounted) {
          setState(() {
            _kecamatanList = kecamatanList;
          });
        }
        return kecamatan.name;
      }
    } catch (e) {
      print('Error getting kecamatan by ID: $e');
    }

    return null;
  }

  DateTime? _parseDate(String value) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _buildAvatarUrl(String avatarPath) {
    try {
      // Create proper URL for avatar, ensuring no duplicate slashes
      String baseUrl = AppConstants.BASE_URL
          .replaceAll('/api', '')
          .replaceAll(RegExp(r'/+'), '/');

      // Ensure the avatar path starts with the appropriate storage directory
      String normalizedAvatarPath = avatarPath.startsWith('storage/')
          ? avatarPath
          : 'storage/$avatarPath';

      // Ensure proper URL format, removing any duplicate slashes and fixing protocol
      String cleanBaseUrl = baseUrl
          .replaceAll(RegExp(r'http:/'), 'http://')
          .replaceAll(RegExp(r'https:/'), 'https://');

      String fullUrl = '$cleanBaseUrl/$normalizedAvatarPath'.replaceAll(
        RegExp(r'([^:])/{2,}'),
        r'$1/',
      );
      print(
        'Building avatar URL - Base: $cleanBaseUrl, Path: $normalizedAvatarPath, Full: $fullUrl',
      );
      return fullUrl;
    } catch (e) {
      print('Error building avatar URL: $e, avatarPath: $avatarPath');
      // Return a default avatar or the original path if building URL fails
      return avatarPath; // Fallback to original path
    }
  }
}
