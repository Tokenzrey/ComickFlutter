import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global navigator key for accessing the root navigator's overlay
/// Add this to your MaterialApp:
/// ```dart
/// return MaterialApp(
///   navigatorKey: CustomPopup.navigatorKey,
///   ...
/// )
/// ```
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

/// Jenis-jenis popup yang didukung oleh [CustomPopup].
///
/// [error]   : Menampilkan popup bertipe kesalahan (biasanya berwarna merah).
/// [success] : Menampilkan popup bertipe keberhasilan (biasanya berwarna hijau).
/// [info]    : Menampilkan popup bertipe informasi (biasanya berwarna biru).
enum PopupType { error, success, info }

/// Kelas utilitas untuk menampilkan notifikasi popup (mirip toast) di atas konten.
///
/// Kelas ini menggunakan [Overlay] dan [OverlayEntry] untuk menampilkan
/// widget pop-up secara global, sehingga bisa muncul di atas seluruh konten aplikasi
/// dan tetap terlihat saat navigasi antar halaman.
///
/// Contoh penggunaan:
/// ```dart
/// CustomPopup.show(
///   message: "Failed to save data",
///   type: PopupType.error,
///   duration: const Duration(seconds: 5),
/// );
/// ```
///
/// Untuk mengaktifkan, tambahkan navigatorKey pada MaterialApp:
/// ```dart
/// MaterialApp(
///   navigatorKey: globalNavigatorKey,
///   home: HomePage(),
/// )
/// ```
class CustomPopup {
  // Menyimpan satu instance _PopupManagerState agar semua popup
  // dikelola oleh widget yang sama
  static _PopupManagerState? _managerState;

  // OverlayEntry global yang menampung _PopupManager
  static OverlayEntry? _overlayEntry;

  // Navigator key untuk akses global overlay
  static GlobalKey<NavigatorState> get navigatorKey => globalNavigatorKey;

  /// Menampilkan popup notifikasi di atas konten.
  ///
  /// [message] : Pesan yang akan ditampilkan.
  /// [type]    : Jenis popup (error, success, info).
  /// [duration]: Lama waktu popup ditampilkan sebelum tertutup otomatis.
  /// [positionFromTop] : Jarak popup dari atas layar (default 60).
  static void show(
    BuildContext context, {
    required String message,
    required PopupType type,
    Duration duration = const Duration(seconds: 10),
    double positionFromTop = 60.0,
    required Null Function() onDismiss,
  }) {
    // Dapatkan overlay dari navigator global
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) {
      if (kDebugMode) {
        print(
          'CustomPopup: Navigator state is null. Make sure to set navigatorKey in MaterialApp.',
        );
      }
      return;
    }

    final overlayState = navigatorState.overlay;
    if (overlayState == null) {
      if (kDebugMode) {
        print('CustomPopup: Overlay state is null.');
      }
      return;
    }

    // Jika _overlayEntry belum ada, buat baru
    if (_overlayEntry == null) {
      // Buat instance _PopupManager
      final manager = _PopupManager(key: UniqueKey());

      // Bungkus _PopupManager di dalam OverlayEntry
      _overlayEntry = OverlayEntry(builder: (_) => manager);

      // Sisipkan OverlayEntry ke dalam overlay
      overlayState.insert(_overlayEntry!);
    }

    // Tambahkan popup ke _managerState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_managerState != null) {
        _managerState!.addPopup(
          message: message,
          type: type,
          duration: duration,
          position: positionFromTop,
        );
      }
    });
  }

  /// Registrasi state [_PopupManagerState] agar [CustomPopup] dapat berkomunikasi.
  /// Method ini dipanggil ketika _PopupManager diinisialisasi (initState).
  static void _registerState(Object state) {
    if (state is _PopupManagerState) {
      _managerState = state;
    }
  }

  /// Unregistrasi state [_PopupManagerState] agar tidak terjadi kebocoran.
  /// Method ini dipanggil ketika _PopupManager di-dispose.
  static void _unregisterState(Object state) {
    if (state is _PopupManagerState && _managerState == state) {
      _managerState = null;
    }
  }

  /// Hapus OverlayEntry ketika semua popup sudah ditutup, agar tidak ada
  /// resource yang tersisa.
  static void _cleanupOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  /// Menutup semua popup yang sedang ditampilkan.
  /// Berguna saat ingin membersihkan semua notifikasi sekaligus.
  static void closeAll() {
    if (_managerState != null) {
      _managerState!.clearAllPopups();
    }
  }
}

/// Widget internal yang bertugas mengelola daftar popup yang sedang tampil.
/// Widget ini dimasukkan sebagai satu-satunya [OverlayEntry].
class _PopupManager extends StatefulWidget {
  const _PopupManager({super.key});

  @override
  _PopupManagerState createState() => _PopupManagerState();
}

/// State dari [_PopupManager] yang menampung daftar popup aktif dan mengatur animasi.
///
/// Menggunakan [TickerProviderStateMixin] agar bisa membuat [AnimationController]
/// untuk animasi fade in/fade out.
class _PopupManagerState extends State<_PopupManager>
    with TickerProviderStateMixin {
  // Menyimpan daftar popup yang sedang tampil
  final List<_PopupEntry> _popupEntries = [];

  // Menandakan apakah widget ini sudah di-dispose (untuk mencegah setState yang invalid)
  bool _isDisposed = false;

  // Jumlah popup maksimum yang dapat ditampilkan
  static const int maxVisiblePopups = 3;

  // Tinggi untuk setiap popup (termasuk margin)
  static const double popupHeight = 80.0;

  // Durasi animasi slide
  static const Duration slideAnimationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    // Registrasi ke CustomPopup agar CustomPopup bisa memanggil addPopup
    CustomPopup._registerState(this);
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Bersihkan sumber daya animasi
    for (final entry in _popupEntries) {
      entry.dispose();
    }
    _popupEntries.clear();

    // Unregister state dari CustomPopup
    CustomPopup._unregisterState(this);
    super.dispose();
  }

  /// Tambahkan popup baru ke daftar
  ///
  /// [message] : Pesan yang akan ditampilkan di popup
  /// [type]    : Tipe popup (error, success, info)
  /// [duration]: Durasi sebelum popup otomatis tertutup
  /// [position]: Jarak dari atas (saat ini tidak dipakai di build, tapi disimpan jika ingin kustom posisi)
  void addPopup({
    required String message,
    required PopupType type,
    required Duration duration,
    double position = 60.0,
  }) {
    if (_isDisposed) return;

    // Buat instance _PopupEntry yang menampung data dan animasi
    final entry = _PopupEntry(
      message: message,
      type: type,
      duration: duration,
      position: position,
      vsync: this,
      onRemove: (e) => removePopup(e),
    );

    // Masukkan entry di index 0 agar popup terbaru muncul di atas (paling awal)
    setState(() {
      _popupEntries.insert(0, entry);

      // Update visibility state untuk semua popup
      _updatePopupsVisibility();
    });

    // Mulai animasi fade in
    entry.fadeIn();
  }

  /// Menghapus popup dari daftar, bisa dengan fade out atau langsung hilang (immediate).
  ///
  /// [entry]     : Popup yang akan dihapus.
  /// [immediate] : Jika true, popup langsung dihapus tanpa animasi.
  void removePopup(_PopupEntry entry, {bool immediate = false}) {
    if (_isDisposed || !_popupEntries.contains(entry)) return;

    // Jika immediate, langsung remove tanpa animasi
    if (immediate) {
      setState(() {
        _popupEntries.remove(entry);

        // Update visibility state untuk popup yang tersisa
        _updatePopupsVisibility();
      });
      entry.dispose();

      // Jika daftar popup kosong, bersihkan overlay
      if (_popupEntries.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_popupEntries.isEmpty) {
            CustomPopup._cleanupOverlay();
          }
        });
      }
    } else {
      // Lakukan fade out sebelum remove
      entry.fadeOut().then((_) {
        if (!_isDisposed) {
          setState(() {
            _popupEntries.remove(entry);

            // Update visibility state untuk popup yang tersisa
            _updatePopupsVisibility();
          });
          entry.dispose();

          // Bersihkan overlay jika sudah tidak ada popup
          if (_popupEntries.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_popupEntries.isEmpty) {
                CustomPopup._cleanupOverlay();
              }
            });
          }
        }
      });
    }
  }

  /// Menghapus semua popup sekaligus
  void clearAllPopups() {
    if (_isDisposed || _popupEntries.isEmpty) return;

    // Hapus semua entri dan bersihkan resource
    setState(() {
      for (final entry in _popupEntries) {
        entry.dispose();
      }
      _popupEntries.clear();
    });

    // Bersihkan overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomPopup._cleanupOverlay();
    });
  }

  /// Update visibility status untuk semua popup
  /// Hanya 3 popup pertama yang akan visible dan timernya berjalan
  void _updatePopupsVisibility() {
    if (_popupEntries.isEmpty) return;

    for (int i = 0; i < _popupEntries.length; i++) {
      if (i < maxVisiblePopups) {
        // Popup di 3 teratas: visible dan timer aktif
        _popupEntries[i].setVisibility(true);
      } else {
        // Popup di luar 3 teratas: invisible dan timer paused
        _popupEntries[i].setVisibility(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada popup yang harus ditampilkan, return SizedBox kosong
    if (_popupEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Hitung tinggi container untuk menampung maksimal 3 popup
    final int visibleCount =
        _popupEntries.length > maxVisiblePopups
            ? maxVisiblePopups
            : _popupEntries.length;
    final double containerHeight = popupHeight * visibleCount;

    // Menggunakan Positioned agar popup muncul di bagian atas layar
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false, // Tetap menerima input touch untuk tombol close/swipe
        child: Material(
          // Menggunakan MaterialType.transparency agar latar belakang tetap tembus pandang
          type: MaterialType.transparency,
          child: SafeArea(
            child: Container(
              height: containerHeight + 8, // Tambah sedikit ruang
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Stack(
                clipBehavior: Clip.none, // Untuk efek shadow yang lebih baik
                children: [
                  // Tampilkan setiap popup dengan posisi yang dianimasi
                  ..._popupEntries.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;

                    // Hanya tampilkan 3 popup pertama
                    if (index >= maxVisiblePopups) {
                      return const SizedBox.shrink();
                    }

                    // Hitung posisi Y untuk setiap popup (posisi vertikal dari atas)
                    final double yPosition = index * popupHeight;

                    return AnimatedPositioned(
                      top: yPosition,
                      left: 0,
                      right: 0,
                      height: popupHeight,
                      duration: slideAnimationDuration,
                      curve: Curves.easeInOut,
                      child: _buildPopupItem(entry, index),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun tampilan tiap popup.
  ///
  /// Menerapkan [Dismissible] agar pengguna dapat melakukan swipe
  /// untuk menutup popup secara langsung.
  Widget _buildPopupItem(_PopupEntry entry, int index) {
    return Dismissible(
      key: entry.key,
      direction: DismissDirection.horizontal,
      onDismissed: (_) => removePopup(entry, immediate: true),
      child: FadeTransition(
        opacity: entry.opacity,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: _PopupCard(entry: entry, onClose: () => removePopup(entry)),
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan satu kartu popup.
///
/// Terdiri dari ikon, teks pesan, dan tombol [X] untuk menutup popup.
class _PopupCard extends StatelessWidget {
  final _PopupEntry entry;
  final VoidCallback onClose;

  const _PopupCard({required this.entry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    // Dapatkan style sesuai tipe popup
    final style = _getStyle(entry.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max, // Gunakan lebar maksimum
        children: [
          // Ikon di sebelah kiri
          Icon(style.icon, color: style.iconColor),
          const SizedBox(width: 12),
          // Teks pesan di tengah dengan scroll vertikal
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Text(
                entry.message,
                style: TextStyle(
                  color: style.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Tombol close (X)
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.close, color: style.iconColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mendapatkan style [backgroundColor], [textColor], [icon], dan [iconColor]
  /// berdasarkan tipe [PopupType].
  _PopupStyle _getStyle(PopupType type) {
    switch (type) {
      case PopupType.error:
        return const _PopupStyle(
          backgroundColor: Color(0xFFD32F2F), // Merah
          textColor: Colors.white,
          icon: Icons.error_outline,
          iconColor: Colors.white,
        );
      case PopupType.success:
        return const _PopupStyle(
          backgroundColor: Color(0xFF2E7D32), // Hijau
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
          iconColor: Colors.white,
        );
      case PopupType.info:
        return const _PopupStyle(
          backgroundColor: Color(0xFF1976D2), // Biru
          textColor: Colors.white,
          icon: Icons.info_outline,
          iconColor: Colors.white,
        );
    }
  }
}

/// Model untuk menampung style dari popup, termasuk warna latar, warna teks, ikon, dsb.
class _PopupStyle {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Color iconColor;

  const _PopupStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.iconColor,
  });
}

/// Kelas internal yang menyimpan data dan animasi untuk satu popup.
///
/// [message] : Pesan yang akan ditampilkan.
/// [type]    : Tipe popup (error, success, info).
/// [duration]: Durasi sebelum popup otomatis tertutup.
/// [position]: Posisi dari atas (saat ini tidak dipakai di tampilan, tapi disimpan untuk kemungkinan penyesuaian).
/// [onRemove] : Callback yang dipanggil untuk menghapus popup dari list di [_PopupManagerState].
class _PopupEntry {
  _PopupEntry({
    required this.message,
    required this.type,
    required this.duration,
    required this.position,
    required TickerProvider vsync,
    required this.onRemove,
  }) : key = UniqueKey() {
    // Buat AnimationController untuk fade in/out
    _controller = AnimationController(
      vsync: vsync,
      duration: _fadeDuration,
      reverseDuration: _fadeDuration,
    );

    // Tween untuk mengatur opasitas (0 -> 1)
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Default state adalah visible
    _isVisible = true;

    // Jalankan timer untuk auto-close popup
    _startTimer();
  }

  final String message;
  final PopupType type;
  final Duration duration;
  final double position;
  final Key key;
  final void Function(_PopupEntry) onRemove;

  // Controller dan animasi untuk fade
  late AnimationController _controller;
  late Animation<double> _opacity;
  Animation<double> get opacity => _opacity;

  // Timer untuk menutup popup secara otomatis
  Timer? _timer;

  // Status visibility
  bool _isVisible = true;

  // Waktu yang sudah terlewat saat popup visible
  Duration _elapsedTime = Duration.zero;

  // Waktu terakhir timer dimulai/dilanjutkan
  DateTime? _lastTimerStartTime;

  // Durasi animasi fade
  static const _fadeDuration = Duration(milliseconds: 300);

  /// Memulai timer berdasarkan [duration]. Jika [duration] terlalu pendek,
  /// minimal durasi total adalah fade in + fade out.
  void _startTimer() {
    final minDuration = _fadeDuration * 2;
    final totalDuration = duration < minDuration ? minDuration : duration;

    // Hitung waktu menunggu sebelum fade out (dikurangi dengan waktu yang sudah terlewat)
    final waitDuration = totalDuration - _elapsedTime - _fadeDuration;

    // Catat waktu mulai timer
    _lastTimerStartTime = DateTime.now();

    _timer = Timer(waitDuration, () {
      // Reset timer variables
      _timer = null;
      _lastTimerStartTime = null;

      fadeOut().then((_) {
        onRemove(this);
      });
    });
  }

  /// Menghentikan timer
  void _pauseTimer() {
    if (_timer != null) {
      // Hitung durasi yang sudah berjalan sejak timer terakhir dimulai
      if (_lastTimerStartTime != null) {
        final now = DateTime.now();
        final timeSinceStart = now.difference(_lastTimerStartTime!);
        _elapsedTime += timeSinceStart;
      }

      // Cancel timer
      _timer?.cancel();
      _timer = null;
      _lastTimerStartTime = null;
    }
  }

  /// Set visibility status (terlihat/tidak terlihat)
  void setVisibility(bool visible) {
    if (_isVisible == visible) return; // No change

    _isVisible = visible;

    if (visible) {
      // Jika menjadi visible, mulai timer lagi
      if (_timer == null && _elapsedTime < duration) {
        _startTimer();
      }
    } else {
      // Jika menjadi invisible, pause timer
      _pauseTimer();
    }
  }

  /// Memulai animasi fade in
  void fadeIn() {
    _controller.forward();
  }

  /// Memulai animasi fade out, mengembalikan [Future] yang selesai saat animasi berakhir
  Future<void> fadeOut() async {
    if (!_controller.isAnimating) {
      if (_controller.status != AnimationStatus.dismissed) {
        try {
          await _controller.reverse();
        } catch (e) {
          // Tangani error animasi agar tidak crash
          if (kDebugMode) {
            print('PopupEntry animation error: $e');
          }
        }
      }
    }
    return Future.value();
  }

  /// Membersihkan sumber daya yang digunakan oleh popup
  void dispose() {
    _timer?.cancel();
    _timer = null;

    if (_controller.isAnimating) {
      _controller.stop();
    }

    _controller.dispose();
  }
}
