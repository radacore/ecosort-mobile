# Summary App - EcoSort

## 📱 Aplikasi Mobile EcoSort

### 🎯 Deskripsi Aplikasi
EcoSort adalah aplikasi pemilah sampah modern yang membantu pengguna dalam melakukan setoran sampah dengan sistem poin dan tracking.

### 🎨 Identitas Visual
- **Nama Aplikasi**: EcoSort
- **Tagline**: Aplikasi Pemilah Sampah Modern
- **Warna Utama**: 
  - Primary: `#368b3a` (Hijau)
  - Secondary: `#2d6e30` (Hijau Tua)

### 📊 Flow Aplikasi

#### 1. **Splash Screen**
- Menampilkan logo EcoSort
- Teks "EcoSort" 
- Subteks "Aplikasi Pemilah Sampah Modern"
- Durasi: 2-3 detik

#### 2. **Authentication Flow**
- **Login Screen**:
  - Form login (email & password)
  - Tombol "Login"
  - Link ke Register ("Belum punya akun? Daftar di sini")
  
- **Register Screen**:
  - Form registrasi (nama, email, password, konfirmasi password)
  - Tombol "Daftar"
  - Link kembali ke Login

#### 3. **Main Application (Setelah Login)**
Navigasi dengan 2 menu utama:

##### **Tab Scan**
- Fitur utama setoran sampah
- Form dengan field:
  - Jenis Sampah (dropdown: Organik, Plastik, dll)
  - Volume (dalam liter)
  - Upload foto sampah
- Tombol "Submit Setoran"
- Display hasil konversi poin

##### **Tab Profile**
- Informasi pengguna:
  - Nama, Email, Alamat
  - Kecamatan
  - Total Points
  - Streak Days
- Form edit profil
- Tombol logout

### 🔗 API Integration

#### Endpoints yang Digunakan:
1. **POST http://127.0.0.1:8000//api/register** - Registrasi pengguna baru
2. **POST http://127.0.0.1:8000//api/login** - Login pengguna
3. **PUT http://127.0.0.1:8000//api/profil** - Update profil pengguna
4. **POST http://127.0.0.1:8000//api/setoran-sampah** - Submit setoran sampah

#### Authentication:
- Menggunakan Bearer Token
- Token disimpan secara secure di device

### 📈 Fitur Utama

#### Sistem Poin:
- Poin diberikan berdasarkan volume dan jenis sampah
- Konversi: volume liter → berat kg → poin
- Streak system untuk konsistensi setoran

#### Klasifikasi Sampah:
- Deteksi otomatis jenis sampah dari foto
- Multiple jenis sampah (Organik, Plastik, dll)

### 🛠 Technical Requirements

#### Platform:
- Mobile App (iOS & Android)

#### State Management:
- User authentication state
- User profile data
- Points & streak tracking
- Scan history

#### Storage:
- Secure token storage
- Cache untuk data kecamatan
- Temporary image storage

### 🎯 User Journey

1. **New User**: Splash → Register → Login → Complete Profile → Start Scanning
2. **Returning User**: Splash → Login → Direct to Scan/Profile

### 📱 UI/UX Considerations
- Green color scheme konsisten
- Simple dan intuitive navigation
- Feedback visual untuk setiap action
- Loading states untuk API calls
- Error handling yang user-friendly

Aplikasi ini dirancang untuk memudahkan masyarakat dalam melakukan setoran sampah dengan sistem reward yang menarik, mendukung program lingkungan yang berkelanjutan.