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
  static const Duration _cacheDuration = Duration(minutes: 5); // Cache for 5 minutes

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
        print('Profile screen already initialized, skipping duplicate initialization');
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
                  district: kecamatanName, // Update district to show the name instead of ID
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
        
        print('Profile loaded successfully - User: ${user?.name}, Avatar: ${user?.avatarPath}');
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
      print('Skipping kecamatan load - already loading: $_isLoadingKecamatan, has data: ${_kecamatanList.isNotEmpty}');
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
          
          // Set default selection if user has a district
          if (_user != null && _user!.district != null) {
            final userDistrict = _user!.district!;
            print('User district: $userDistrict');
            try {
              _selectedKecamatan = _kecamatanList.firstWhere(
                (kecamatan) => kecamatan.name == userDistrict,
              );
              print('Matched kecamatan: ${_selectedKecamatan?.name}');
            } catch (e) {
              print('No matching kecamatan found, selecting first');
              if (_kecamatanList.isNotEmpty) {
                _selectedKecamatan = _kecamatanList.first;
              }
            }
          } else if (_kecamatanList.isNotEmpty) {
            print('No user district, selecting first kecamatan');
            _selectedKecamatan = _kecamatanList.first;
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
    print('Selected Kecamatan: ${_selectedKecamatan?.name} (ID: ${_selectedKecamatan?.id})');
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
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        confirmPassword: _passwordController.text.isNotEmpty ? _confirmPasswordController.text : null,
      );

      if (updatedUser != null) {
        // Check if the updated user has kecamatan ID instead of name, and try to convert it
        String? finalDistrictName = updatedUser.district;
        if (finalDistrictName != null && int.tryParse(finalDistrictName) != null) {
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
            district: finalDistrictName, // Use the name if available, otherwise the ID
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
    final validatedDeposits =
        _wasteHistory.where((deposit) => deposit.isValidated).toList();

    _calculatedPoints = validatedDeposits.length;

    if (validatedDeposits.isEmpty) {
      _calculatedStreakDays = 0;
      return;
    }

    final dates = validatedDeposits
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
      print('Skipping waste history load - already loading: $_isLoadingHistory, has data: ${_wasteHistory.isNotEmpty}');
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
              content: Text('Tidak dapat menentukan pengguna. Silakan coba lagi.'),
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
          
          print('Avatar uploaded successfully and state updated directly');
          print('Updated user has district: ${updatedUser.district}');
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
    print('Building Profile Screen - currentTab: $_currentTab');
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: const Color(0xFF368b3a),
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Profil'),
              Tab(text: 'Riwayat'),
            ],
            onTap: (index) {
              print('Tab tapped: $index');
              setState(() {
                _currentTab = index;
                if (index == 1 && (_wasteHistory.isEmpty || !_isLoadingHistory)) {
                  _loadWasteHistory();
                }
              });
            },
          ),
          actions: [
            if (_isEditing && _currentTab == 0)
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        body: TabBarView(
          children: [
            // Profile Tab
            _buildProfileContent(),
            // History Tab
            _buildHistoryContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    print('Building profile content - isLoading: $_isLoading, user: ${_user?.name}');
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: _user == null
                ? const Center(
                    child: Text('Gagal memuat data pengguna'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF368b3a),
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _user?.avatarPath != null 
                                ? (() {
                                    print('Avatar path available: ${_user!.avatarPath}');
                                    print('Built avatar URL: ${_buildAvatarUrl(_user!.avatarPath!)}');
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.network(
                                        _buildAvatarUrl(_user!.avatarPath!),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading avatar image: $error, URL: ${_buildAvatarUrl(_user!.avatarPath!)}');
                                          return Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.white,
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            print('Avatar image loaded: ${_buildAvatarUrl(_user!.avatarPath!)}');
                                            return child;
                                          }
                                          print('Avatar image loading...');
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF368b3a),
                                              borderRadius: BorderRadius.circular(60),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 30,
                                                height: 30,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  })()
                                : (() {
                                    print('No avatar path available, showing default icon');
                                    return Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    );
                                  })(),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF368b3a),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: _isUploadingAvatar
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: _pickImage,
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (!_isEditing) ...[
                        Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Nama', _user!.name),
                                const Divider(height: 20, color: Colors.grey),
                                _buildInfoRow('Email', _user!.email),
                                const Divider(height: 20, color: Colors.grey),
                                _buildInfoRow('Alamat', _user!.address ?? '-'),
                                const Divider(height: 20, color: Colors.grey),
                                _buildInfoRow('Kecamatan', _user!.district ?? '-'),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Poin',
                                _calculatedPoints.toString(),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                'Streak Hari',
                                '${_calculatedStreakDays} hari',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF368b3a),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Edit Profil'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ] else ...[
                        Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nama',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF368b3a),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Alamat',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF368b3a),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _isLoadingKecamatan
                                    ? const CircularProgressIndicator()
                                    : _kecamatanList.isEmpty
                                        ? const Text('No kecamatan data available')
                                        : DropdownButtonFormField<Kecamatan>(
                                            value: _selectedKecamatan,
                                            hint: const Text('Pilih Kecamatan'),
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              labelText: 'Kecamatan',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF368b3a),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            items: _kecamatanList.map((kecamatan) {
                                              print('Building dropdown item: ${kecamatan.name}');
                                              return DropdownMenuItem<Kecamatan>(
                                                value: kecamatan,
                                                child: Text(
                                                  kecamatan.name,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (Kecamatan? newValue) {
                                              print('Selected kecamatan: ${newValue?.name}');
                                              setState(() {
                                                _selectedKecamatan = newValue;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Please select a kecamatan';
                                              }
                                              return null;
                                            },
                                            dropdownColor: Colors.white,
                                            menuMaxHeight: 300,
                                          ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password Baru (Opsional)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF368b3a),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Konfirmasi Password Baru',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF368b3a),
                                        width: 2,
                                      ),
                                    ),
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
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF368b3a),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Simpan Perubahan'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
          );
  }

  Widget _buildHistoryContent() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_wasteHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada riwayat penyetoran',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _wasteHistory.length,
        itemBuilder: (context, index) {
          final deposit = _wasteHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTrashTypeDisplayName(deposit.trashType),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                          'Volume: ${deposit.volumeLiters.toStringAsFixed(2)} L',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                          'Berat: ${deposit.weightKg.toStringAsFixed(2)} Kg',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                      color: deposit.isValidated
                          ? const Color(0xFF368b3a)
                          : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                      deposit.isValidated ? 'Tervalidasi' : 'Menunggu Validasi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                  'Waktu Setoran: ${_formatDate(deposit.timestamp)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      color: const Color(0xFF368b3a),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
      String baseUrl = AppConstants.BASE_URL.replaceAll('/api', '').replaceAll(RegExp(r'/+'), '/');
      
      // Ensure the avatar path starts with the appropriate storage directory
      String normalizedAvatarPath = avatarPath.startsWith('storage/') ? avatarPath : 'storage/$avatarPath';
      
      // Ensure proper URL format, removing any duplicate slashes and fixing protocol
      String cleanBaseUrl = baseUrl.replaceAll(RegExp(r'http:/'), 'http://').replaceAll(RegExp(r'https:/'), 'https://');
      
      String fullUrl = '$cleanBaseUrl/$normalizedAvatarPath'.replaceAll(RegExp(r'([^:])/{2,}'), r'$1/');
      print('Building avatar URL - Base: $cleanBaseUrl, Path: $normalizedAvatarPath, Full: $fullUrl');
      return fullUrl;
    } catch (e) {
      print('Error building avatar URL: $e, avatarPath: $avatarPath');
      // Return a default avatar or the original path if building URL fails
      return avatarPath; // Fallback to original path
    }
  }
}