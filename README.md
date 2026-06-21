Konsep Flutter App — Dok. Ziaroh Suran
📱 Flow & Fitur
Kode
📋 Halaman & Fitur
1. Home / Upload
Form nama + divisi (auto-simpan ke SharedPreferences)
Keterangan opsional
Picker foto/video (multi-select dari galeri/kamera)
Upload satu per satu dengan progress bar per file
Status sukses/gagal per file
2. Riwayat Saya
Daftar file yang pernah diupload dari HP ini
Thumbnail foto, icon video
Info: nama file, ukuran, waktu, divisi
3. Semua File (Galeri Tim)
Grid view semua file dari semua pengirim
Filter: Divisi, Tipe (foto/video), Pengirim
Tap → Preview foto fullscreen / putar video
Tidak ada hapus (biar simpel, hapus dari web admin)
🔧 Tech Stack


HTTP
dio (upload multipart + progress)
Media picker
image_picker + file_picker
Storage lokal
shared_preferences
Video player
video_player + chewie
State
setState sederhana
UI
Material 3, tema hijau-emas
🔌 API yang dibutuhkan (tambah di backend)
Endpoint
Fungsi
POST upload.php
Upload file (sudah ada)
GET api.php?action=list
Daftar semua file
GET api.php?action=list&nama=X
Filter per pengirim
Perlu tambah 1 file api.php di backend.