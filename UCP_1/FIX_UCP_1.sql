
-- ================================================================
--            BAGIAN A – DDL & ARSITEKTUR DATABASE
-- ================================================================

-- ===========================================
-- SOAL 1: Perancangan Database Monitoring TA 
-- ===========================================
USE master;
GO

CREATE DATABASE D_Monitoring_TA
ON PRIMARY (
    -- File Utama (.mdf)
    NAME = 'MonitoringTA_Primary',
    FILENAME = 'D:\SQLData\MonitoringTA_Primary.mdf', 
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
),
FILEGROUP FG_Monitoring_TA (
    -- File Sekunder (.ndf)
    NAME = 'MonitoringTA_Secondary',
    FILENAME = 'D:\SQLData\MonitoringTA_Secondary.ndf', 
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
)
LOG ON (
    -- Log File (.ldf)
    NAME = 'MonitoringTA_Log',
    FILENAME = 'D:\SQLData\MonitoringTA_Log.ldf', 
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
);
GO

-- Verifikasi
SELECT name AS DatabaseName, state_desc 
FROM sys.databases 
WHERE name = 'D_Monitoring_TA';
GO

/*
Fungsi Masing-masing File:
•	.mdf (Primary Data File): File utama yang berisi data startup dan tabel sistem (metadata). Setiap database wajib memiliki satu file .mdf.
•	.ndf (Secondary Data File): File tambahan untuk menyimpan data. Digunakan jika data sudah sangat besar sehingga perlu dipecah ke disk yang berbeda untuk meningkatkan performa I/O.
•	.ldf (Transaction Log File): Menyimpan catatan semua transaksi yang terjadi di database. Ini krusial untuk proses recovery atau rollback data jika terjadi kegagalan sistem.

Alasan Pembagian Data Utama & Sekunder:
•	Untuk performa (I/O Parallelism): Dengan menempatkan .mdf dan .ndf pada disk fisik yang berbeda, server bisa membaca/menulis data secara bersamaan, sehingga mempercepat akses database.
•	Untuk manajemen kapasitas: Memudahkan admin dalam mengatur lokasi penyimpanan data yang sudah penuh.

Dampak jika Log File (.ldf) terlalu kecil:
•	Jika transaksi sedang tinggi (misalnya banyak insert atau update), log file akan cepat penuh. Jika log file mencapai MAXSIZE dan tidak bisa tumbuh lagi, maka database akan menghentikan seluruh transaksi (bisa menyebabkan aplikasi hang atau error saat menyimpan data).
*/



-- ===========================================
-- SOAL 2: CREATE, ALTER, DROP 
-- ===========================================
USE D_Monitoring_TA;
GO

-- Membuat Schema
CREATE SCHEMA akademik;   
GO
CREATE SCHEMA aktivitas;  
GO
CREATE SCHEMA arsip;      
GO

-- Membuat Tabel Induk
-- 1. TABEL MAHASISWA
CREATE TABLE akademik.Mahasiswa (
    Nim CHAR(11) PRIMARY KEY,
    Nama VARCHAR(50) NOT NULL,
    Jurusan VARCHAR(30),
    Angkatan INT
);

-- 2. TABEL DOSEN 
CREATE TABLE akademik.Dosen (
    NIDN CHAR(10) PRIMARY KEY,
    Nama VARCHAR(50) NOT NULL,
    Prodi VARCHAR(30),
    Email VARCHAR(30),
    CONSTRAINT UQ_Email_Dosen UNIQUE (Email) 
);

-- 3. TABEL STAFF TU
CREATE TABLE akademik.Staff_TU (
    ID_Staff INT IDENTITY(1,1) PRIMARY KEY,
    NIP VARCHAR(50) NOT NULL,
    Jabatan VARCHAR(30),
    Email VARCHAR(50),
    CONSTRAINT UQ_NIP_Staff   UNIQUE (NIP),
    CONSTRAINT UQ_Email_Staff UNIQUE (Email),
    CONSTRAINT CHK_Jabatan_Staff 
        CHECK (Jabatan IN ('Kepala TU', 'Staff Administrasi', 'Staff Keuangan', 'Staff Akademik'))
);

-- Membuat Tabel Anak
-- 4. TABEL MONITORING_TA
CREATE TABLE aktivitas.Monitoring_TA (
    ID_TA INT IDENTITY(1,1) PRIMARY KEY,
    Nim CHAR(11) NOT NULL,
    NIDN_Pembimbing CHAR(10) NOT NULL,
    Judul_TA VARCHAR(255) NOT NULL,
    Status_TA VARCHAR(20) DEFAULT 'Aktif',
    CONSTRAINT FK_Monitoring_Mhs FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim),
    CONSTRAINT FK_Monitoring_Dosen FOREIGN KEY (NIDN_Pembimbing) REFERENCES akademik.Dosen(NIDN),
    CONSTRAINT CHK_Status CHECK (Status_TA IN ('Aktif', 'Lulus', 'Berhenti')) 
) ON FG_Monitoring_TA;

-- 5. TABEL LOG BIMBINGAN
CREATE TABLE aktivitas.Log_Bimbingan (
    ID_Log INT IDENTITY(1,1) PRIMARY KEY, 
    Nim CHAR(11) NOT NULL, 
    NIDN CHAR(10) NOT NULL, 
    Tanggal DATE,
    Materi TEXT,
    Status VARCHAR(20),
    CONSTRAINT FK_Log_Mhs FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim),
    CONSTRAINT FK_Log_Dosen FOREIGN KEY (NIDN) REFERENCES akademik.Dosen(NIDN)
);

-- 6. TABEL PENGAJUAN PENDADARAN
CREATE TABLE aktivitas.Pengajuan_Pendadaran (
    ID_Pengajuan INT IDENTITY(1,1) PRIMARY KEY,
    ID_TA INT NOT NULL, 
    NIDN_Penguji1 CHAR(10) NOT NULL,
    NIDN_Penguji2 CHAR(10) NOT NULL,
    IPK DECIMAL(3,2) NOT NULL,
    SKS_Lulus INT NOT NULL,
    Tanggal_Pengajuan DATE NOT NULL DEFAULT GETDATE(),
    Tanggal_Ujian DATE,
    Ruangan VARCHAR(30),
    Status VARCHAR(20) NOT NULL DEFAULT 'Menunggu',
    Nilai CHAR(2),
    Catatan VARCHAR(500),
    -- Relasi
    CONSTRAINT FK_Pendadaran_TA
        FOREIGN KEY (ID_TA) REFERENCES aktivitas.Monitoring_TA(ID_TA),
    CONSTRAINT FK_Pendadaran_Penguji1
        FOREIGN KEY (NIDN_Penguji1) REFERENCES akademik.Dosen(NIDN),
    CONSTRAINT FK_Pendadaran_Penguji2
        FOREIGN KEY (NIDN_Penguji2) REFERENCES akademik.Dosen(NIDN),
    -- Validasi
    CONSTRAINT CHK_Status_Pendadaran
        CHECK (Status IN ('Menunggu', 'Disetujui', 'Ditolak', 'Selesai')),
    CONSTRAINT CHK_IPK
        CHECK (IPK BETWEEN 0.00 AND 4.00), -- Menggunakan BETWEEN lebih simpel
    CONSTRAINT CHK_SKS
        CHECK (SKS_Lulus >= 0)
);

-- 7. TABEL ARSIP
CREATE TABLE arsip.Arsip_TA (
    ID_Arsip INT IDENTITY(1,1) PRIMARY KEY,
    ID_TA INT,
    Tanggal_Arsip DATE DEFAULT GETDATE(), 
    CONSTRAINT FK_Arsip_TA FOREIGN KEY (ID_TA) REFERENCES aktivitas.Monitoring_TA(ID_TA)
);

-- Menabahkan Data
USE D_Monitoring_TA;
GO

-- 1. Tambah Data Mahasiswa 
INSERT INTO master.Mahasiswa (Nim, Nama, Jurusan, Angkatan)
VALUES ('20250140157', 'Ahmad Rassya Maulana', 'Teknologi Informasi', 2025),
       ('20250140175', 'Muhammad Raffi Imdad Robbani', 'Teknologi Informasi', 2025);

-- 2. Tambah Data Dosen 
INSERT INTO master.Dosen (NIDN, Nama, Prodi, Email)
VALUES ('0518048401', 'Apriliya Kurnianti, S.T., M.Eng.', 'Teknologi Informasi', 'aprilia@ft.umy.ac.id'),
       ('0707108402', 'Chayadi Oktomy N S, S.T., M.Eng., P.hD.', 'Teknologi Informasi', 'cahyadions@ft.umy.ac.id');

-- 3. Tambah Data Staff TU
INSERT INTO master.Staff_TU (NIP, Jabatan, Email)
VALUES ('1234567890', 'Kepala TU', 'budi@ft.umy.ac.id'),
       ('0987654321', 'Staff Administrasi', 'siti@ft.umy.ac.id');

-- 4. Tambah Data Monitoring TA 
INSERT INTO akademik.Monitoring_TA (Nim, NIDN_Pembimbing, Judul_TA)
VALUES ('20250140157', '0518048401', 'Pengembangan AI untuk Deteksi Hama');

-- 5. Tambah Data Log Bimbingan
INSERT INTO aktivitas.Log_Bimbingan (Nim, NIDN, Tanggal, Materi, Status)
VALUES ('20250140157', '0518048401', GETDATE(), 'Pembahasan Bab 1 Latar Belakang', 'Revisi');

-- 6. Tambah Data Pengajuan Pendadaran
INSERT INTO akademik.Pengajuan_Pendadaran (ID_TA, NIDN_Penguji1, NIDN_Penguji2, IPK, SKS_Lulus, Tanggal_Pengajuan, Tanggal_Ujian, Ruangan, Status, Nilai, Catatan)
VALUES (1, '0707108402', '0518048401', 3.75, 144, GETDATE(), '2026-06-01', 'Ruang Sidang A', 'Menunggu', NULL, 'Semua persyaratan telah terpenuhi'),
       (1, '0518048401', '0707108402', 3.80, 148, GETDATE(), '2026-06-05', 'Ruang Sidang B', 'Menunggu', NULL, 'Menunggu verifikasi berkas');

-- VERIFIKASI Cek data yang sudah masuk (Uji Relasi)
SELECT m.Nama, ta.Judul_TA, ta.Status_TA
FROM aktivitas.Monitoring_TA ta
JOIN akademik.Mahasiswa m ON ta.Nim = m.Nim;
GO       

-- Melihat Data Seluruh Tabel
-- Melihat semua data Mahasiswa
SELECT * FROM akademik.Mahasiswa;

-- Melihat semua data Dosen
SELECT * FROM akademik.Dosen;

-- Melihat semua data Monitoring TA
SELECT * FROM aktivitas.Monitoring_TA;

-- Melihat semua data Log Bimbingan
SELECT * FROM akademik.Log_Bimbingan;

-- Melihat semua data Pengajuan Pendadaran
SELECT * FROM akademik.Pengajuan_Pendadaran;

-- Melihat semua data Staff TU
SELECT * FROM akademik.Staff_TU;

-- ALTER TABLE: Menambahkan 2 kolom baru
ALTER TABLE akademik.Mahasiswa
ADD No_HP VARCHAR(13),
    Alamat VARCHAR(255);
GO

-- DROP Kolom: Menghapus satu kolom alamat dari tabel Mahasiswa
ALTER TABLE akademik.Mahasiswa
DROP COLUMN Alamat
GO

-- DROP Tabel: Menghapus satu tabel yang tidak diperlukan (arsip)
DROP TABLE arsip.Arsip_TA;
GO

-- VERIFIKASI Pastikan schema arsip sudah hilang
SELECT name FROM sys.schemas WHERE name = 'arsip';
GO

/*
Kapan ALTER Lebih Tepat Dibanding DROP & CREATE Ulang?
Perintah ALTER adalah pilihan utama dalam lingkungan produksi karena sifatnya yang inkremental (memodifikasi tanpa menghapus). 

wajib menggunakan ALTER jika:
•	Data Eksisting Sangat Berharga: Jika tabel sudah berisi jutaan baris data, melakukan DROP dan CREATE berarti kamu harus memindahkan (migrate) seluruh data tersebut ke tabel baru. Ini memakan waktu, menguras I/O disk, dan berisiko kehilangan data jika proses copy gagal.
•	Dependency yang Kompleks: Tabel seringkali memiliki relasi (Foreign Key), Stored Procedure, View, atau Trigger yang merujuk padanya. Jika kamu melakukan DROP, maka seluruh objek yang bergantung pada tabel tersebut akan menjadi invalid (rusak). ALTER memungkinkan perubahan kolom tanpa memutuskan relasi tersebut.
•	Waktu Eksekusi (Uptime): ALTER biasanya jauh lebih cepat daripada membuat ulang tabel dan mengimpor kembali data. Dalam sistem yang harus berjalan 24/7, setiap detik downtime sangatlah berharga.

Gunakan DROP & CREATE jika:
•	Perubahan struktur sangat masif (hampir seluruh skema tabel berubah).
•	Database berada di lingkungan pengembangan (Development) atau staging di mana data tidak bersifat permanen atau kritikal.

Risiko Penggunaan DROP pada Database Produksi
Melakukan DROP pada database produksi adalah tindakan "berisiko tinggi" yang harus dihindari kecuali dalam skenario migrasi yang sangat terkontrol. Berikut risikonya:
•	Kehilangan Data Permanen: Ini adalah risiko terbesar. Perintah DROP tidak masuk dalam log transaksi yang bisa dengan mudah di-rollback seperti perintah DELETE. Jika tidak ada backup terbaru, data hilang selamanya.
•	Downtime Sistem: Saat tabel di-drop, aplikasi yang mencoba mengakses tabel tersebut akan langsung mengalami error (seperti Invalid Object Name), yang menyebabkan layanan terputus bagi pengguna.
•	Kerusakan Integritas Referensial: Jika kamu mencoba melakukan DROP pada tabel yang menjadi parent dari tabel lain (memiliki Foreign Key), SQL Server akan menolak eksekusi tersebut kecuali kamu menghapus constraint-nya satu per satu. Jika kamu terpaksa menghapus constraint tersebut, kamu berisiko merusak hubungan data yang sudah tersusun rapi.
•	Invalidasi Objek Bergantung: Seluruh View, Stored Procedure, atau Function yang menggunakan tabel tersebut akan menjadi tidak valid (invalid). Kamu harus melakukan pengecekan ulang dan melakukan recompile pada semua objek tersebut.
*/




-- ================================================================
--          BAGIAN B – TIPE DATA & STRATEGI PENYIMPANAN 
-- ================================================================

-- ===========================================
-- SOAL 3: Analisis Pemilihan Tipe Data 
-- ===========================================
-- (Di Exel)


-- ===========================================
-- Soal 4: Optimasi Storage dan I/O 
-- ===========================================
-- (Di Exel)




-- ================================================================
-- BAGIAN C – INTEGRITAS DATA & CONSTRAINTS 
-- ================================================================

-- ===========================================
-- Soal 5 – Constraint dan Relasi 
-- ===========================================
-- Sudah ada constrain dan relasi pada tabel diatas yang mencangkup:
-- 1. Primary Key pada setiap tabel 
-- 2. Foreign Key 
-- 3. Check Constraint 
-- 4. Default Constraint 
-- 5. Unique Constraint 
-- 6. Not Null Constraint

/* 
===============================
 fungsi masing-masing constraint
 ===============================
1. Primary Key menolak data dengan nilai kunci yang sama.
2. Foreign Key menolak data yang tidak memiliki pasangan pada tabel induk.
3. Unique Constraint menolak data duplikat.
4. Check Constraint menolak data yang tidak memenuhi aturan bisnis.
5. Not Null Constraint menolak data kosong (NULL).
6. Default Constraint memberikan nilai otomatis jika kolom tidak diisi.

PRIMARY KEY:
1. Mahasiswa.Nim
   Fungsi: Menjadi identitas unik setiap mahasiswa sehingga tidak ada dua mahasiswa yang memiliki NIM yang sama.
2. Dosen.NIDN
   Fungsi: Menjadi identitas unik setiap dosen dalam sistem.
3. Staff_TU.ID_Staff
   Fungsi: Menjadi identitas unik setiap staf tata usaha.
4. Monitoring_TA.ID_TA
   Fungsi: Menjadi identitas unik setiap data tugas akhir yang dimonitor.
5. Log_Bimbingan.ID_Log
   Fungsi: Menjadi identitas unik setiap catatan bimbingan mahasiswa.
6. Pengajuan_Pendadaran.ID_Pengajuan
   Fungsi: Menjadi identitas unik setiap pengajuan pendadaran.
7. Arsip_TA.ID_Arsip
   Fungsi: Menjadi identitas unik setiap arsip tugas akhir.

FOREIGN KEY:
1. FK_Monitoring_Mhs
   Fungsi: Memastikan mahasiswa yang tercatat pada Monitoring_TA sudah terdaftar pada tabel Mahasiswa.
2. FK_Monitoring_Dose
   Fungsi: Memastikan dosen pembimbing yang tercatat pada Monitoring_TA sudah terdaftar pada tabel Dosen.
3. FK_Log_Mh
   Fungsi: Memastikan log bimbingan hanya dapat dibuat untuk mahasiswa yang terdaftar.
4. FK_Log_Dosen
   Fungsi: Memastikan dosen yang melakukan bimbingan sudah terdaftar pada tabel Dosen.
5. FK_Pendadaran_TA
   Fungsi: Memastikan pengajuan pendadaran berasal dari data tugas akhir yang valid.
6. FK_Pendadaran_Penguji1
   Fungsi: Memastikan penguji pertama merupakan dosen yang terdaftar dalam sistem.
7. FK_Pendadaran_Penguji2
   Fungsi: Memastikan penguji kedua merupakan dosen yang terdaftar dalam sistem.
8. FK_Arsip_TA
   Fungsi: Memastikan arsip tugas akhir berasal dari data tugas akhir yang valid.

UNIQUE CONSTRAINT
1. UQ_Email_Dosen
   Fungsi: Memastikan setiap dosen memiliki alamat email yang unik dan tidak boleh duplikat.
2. UQ_NIP_Staff
   Fungsi: Memastikan setiap staf memiliki NIP yang unik.
3. UQ_Email_Staff
   Fungsi: Memastikan setiap staf memiliki alamat email yang unik dan tidak boleh duplikat.

CHECK CONSTRAINT
1. CHK_Jabatan_Staff
   Fungsi: Membatasi nilai jabatan staf hanya pada pilihan yang telah ditentukan oleh sistem.
2. CHK_Status
   Fungsi: Membatasi nilai status tugas akhir hanya Aktif, Lulus, atau Berhenti.
3. CHK_Status_Pendadaran
   Fungsi: Membatasi nilai status pendadaran hanya Menunggu, Disetujui, Ditolak, atau Selesai.
4. CHK_IPK
   Fungsi: Memastikan nilai IPK berada dalam rentang 0.00 sampai 4.00.
5. CHK_SKS
   Fungsi: Memastikan jumlah SKS lulus tidak bernilai negatif.

DEFAULT CONSTRAINT
1. Monitoring_TA.Status_TA
   Fungsi: Memberikan nilai otomatis 'Aktif' apabila status tugas akhir tidak diisi saat proses input data.
2. Pengajuan_Pendadaran.Tanggal_Pengajuan
   Fungsi: Mengisi tanggal pengajuan secara otomatis sesuai tanggal saat data dibuat.
3. Pengajuan_Pendadaran.Status
   Fungsi: Memberikan nilai awal 'Menunggu' apabila status pengajuan tidak diisi.
4. Arsip_TA.Tanggal_Arsip
   Fungsi: Mengisi tanggal arsip secara otomatis sesuai tanggal saat data arsip dibuat.

NOT NULL CONSTRAINT
1. Mahasiswa.Nama
   Fungsi: Memastikan nama mahasiswa wajib diisi.
2. Dosen.Nama
   Fungsi: Memastikan nama dosen wajib diisi.
3. Staff_TU.NIP
   Fungsi: Memastikan NIP staf wajib diisi.
4. Monitoring_TA.Nim
   Fungsi: Memastikan setiap data tugas akhir memiliki mahasiswa yang valid.
5. Monitoring_TA.NIDN_Pembimbing
   Fungsi: Memastikan setiap tugas akhir memiliki dosen pembimbing.
6. Monitoring_TA.Judul_TA
   Fungsi: Memastikan judul tugas akhir wajib diisi.
7. Pengajuan_Pendadaran.ID_TA
   Fungsi: Memastikan data tugas akhir yang diajukan untuk pendadaran wajib diisi.
8. Pengajuan_Pendadaran.NIDN_Penguji1
   Fungsi: Memastikan dosen penguji pertama wajib ditentukan.
9. Pengajuan_Pendadaran.NIDN_Penguji2
   Fungsi: Memastikan dosen penguji kedua wajib ditentukan.
10. Pengajuan_Pendadaran.IPK
    Fungsi: Memastikan nilai IPK mahasiswa wajib diisi.
11. Pengajuan_Pendadaran.SKS_Lulus
    Fungsi: Memastikan jumlah SKS lulus wajib diisi.
12. Pengajuan_Pendadaran.Tanggal_Pengajuan
    Fungsi: Memastikan tanggal pengajuan pendadaran selalu tersedia.
13. Pengajuan_Pendadaran.Status
    Fungsi: Memastikan status pengajuan pendadaran wajib memiliki nilai.
*/

/*
=============================================
contoh data yang akan ditolak oleh constraint
=============================================
1. PRIMARY KEY
Mahasiswa.Nim
Contoh yang ditolak:
NIM = '20250140157' dimasukkan kembali padahal sudah ada di tabel Mahasiswa.

Dosen.NIDN
Contoh yang ditolak:
NIDN = '0518048401' dimasukkan kembali padahal sudah ada di tabel Dosen.

Staff_TU.ID_Staff
Contoh yang ditolak:
ID_Staff yang sama digunakan lebih dari satu data.


2. FOREIGN KEY
FK_Monitoring_Mhs
Contoh yang ditolak:
INSERT Monitoring_TA dengan Nim = '99999999999'
padahal NIM tersebut tidak ada pada tabel Mahasiswa.

FK_Monitoring_Dosen
Contoh yang ditolak:
INSERT Monitoring_TA dengan NIDN_Pembimbing = '1111111111'
padahal NIDN tersebut tidak ada pada tabel Dosen.

FK_Log_Mhs
Contoh yang ditolak:
INSERT Log_Bimbingan dengan Nim yang tidak terdaftar pada tabel Mahasiswa.

FK_Log_Dosen
Contoh yang ditolak:
INSERT Log_Bimbingan dengan NIDN yang tidak terdaftar pada tabel Dosen.

FK_Pendadaran_TA
Contoh yang ditolak:
INSERT Pengajuan_Pendadaran dengan ID_TA = 999
padahal ID_TA tersebut tidak ada pada tabel Monitoring_TA.

FK_Pendadaran_Penguji1
Contoh yang ditolak:
NIDN_Penguji1 tidak terdaftar pada tabel Dosen.

FK_Pendadaran_Penguji2
Contoh yang ditolak:
NIDN_Penguji2 tidak terdaftar pada tabel Dosen.

FK_Arsip_TA
Contoh yang ditolak:
ID_TA yang diarsipkan tidak terdapat pada tabel Monitoring_TA.


3. UNIQUE CONSTRAINT
UQ_Email_Dosen
Contoh yang ditolak:
Email = 'aprilia@ft.umy.ac.id'
dimasukkan untuk dosen lain padahal sudah digunakan.

UQ_NIP_Staff
Contoh yang ditolak:
NIP = '1234567890'
dimasukkan kembali pada data staff yang berbeda.

UQ_Email_Staff
Contoh yang ditolak:
Email = 'budi@ft.umy.ac.id'
digunakan oleh lebih dari satu staff.


4. CHECK CONSTRAINT
CHK_Jabatan_Staff
Contoh yang ditolak:
Jabatan = 'Manager'

Karena hanya diperbolehkan:
- Kepala TU
- Staff Administrasi
- Staff Keuangan
- Staff Akademik

CHK_Status
Contoh yang ditolak:
Status_TA = 'Pending'

Karena hanya diperbolehkan:
- Aktif
- Lulus
- Berhenti

CHK_Status_Pendadaran
Contoh yang ditolak:
Status = 'Proses'

Karena hanya diperbolehkan:
- Menunggu
- Disetujui
- Ditolak
- Selesai

CHK_IPK
Contoh yang ditolak:
IPK = 4.50

Karena IPK harus berada pada rentang 0.00 – 4.00.

CHK_SKS
Contoh yang ditolak:
SKS_Lulus = -10

Karena jumlah SKS tidak boleh bernilai negatif.


5. DEFAULT CONSTRAINT
Monitoring_TA.Status_TA
Contoh yang ditolak:
Tidak ada.

Karena jika kolom tidak diisi, SQL Server otomatis mengisi nilai 'Aktif'.

Pengajuan_Pendadaran.Tanggal_Pengajuan
Contoh yang ditolak:
Tidak ada.

Karena jika kolom tidak diisi, SQL Server otomatis mengisi tanggal saat ini.

Pengajuan_Pendadaran.Status
Contoh yang ditolak:
Tidak ada.

Karena jika kolom tidak diisi, SQL Server otomatis mengisi nilai 'Menunggu'.

Arsip_TA.Tanggal_Arsip
Contoh yang ditolak:
Tidak ada.

Karena jika kolom tidak diisi, SQL Server otomatis mengisi tanggal saat ini.


6. NOT NULL CONSTRAINT
Mahasiswa.Nama
Contoh yang ditolak:
Nama = NULL

Dosen.Nama
Contoh yang ditolak:
Nama = NULL

Staff_TU.NIP
Contoh yang ditolak:
NIP = NULL

Monitoring_TA.Nim
Contoh yang ditolak:
Nim = NULL

Monitoring_TA.NIDN_Pembimbing
Contoh yang ditolak:
NIDN_Pembimbing = NULL

Monitoring_TA.Judul_TA
Contoh yang ditolak:
Judul_TA = NULL

Pengajuan_Pendadaran.ID_TA
Contoh yang ditolak:
ID_TA = NULL

Pengajuan_Pendadaran.NIDN_Penguji1
Contoh yang ditolak:
NIDN_Penguji1 = NULL

Pengajuan_Pendadaran.NIDN_Penguji2
Contoh yang ditolak:
NIDN_Penguji2 = NULL

Pengajuan_Pendadaran.IPK
Contoh yang ditolak:
IPK = NULL

Pengajuan_Pendadaran.SKS_Lulus
Contoh yang ditolak:
SKS_Lulus = NULL

Pengajuan_Pendadaran.Tanggal_Pengajuan
Contoh yang ditolak:
Tanggal_Pengajuan = NULL

Pengajuan_Pendadaran.Status
Contoh yang ditolak:
Status = NULL
*/


-- ===========================================
-- Soal 6 – Referential Integrity 
-- ===========================================
-- 1. ON DELETE CASCADE
ALTER TABLE aktivitas.Monitoring_TA
ADD CONSTRAINT FK_Monitoring_Mhs_Cascade 
FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim)
ON DELETE CASCADE;

-- 2. ON DELETE SET NULL
ALTER TABLE aktivitas.Monitoring_TA
ADD CONSTRAINT FK_Monitoring_Mhs_SetNull 
FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim)
ON DELETE SET NULL;

-- 3. ON DELETE NO ACTION 
ALTER TABLE aktivitas.Monitoring_TA
ADD CONSTRAINT FK_Monitoring_Mhs_NoAction 
FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim)
ON DELETE NO ACTION;

/*
1.Kapan Masing-Masing Aturan Paling Tepat Digunakan?
•	ON DELETE CASCADE
•	Kapan: Gunakan saat data anak tidak memiliki makna atau nilai bisnis jika data induknya hilang.
•	Contoh: Tabel Log_Bimbingan (tabel anak) sangat bergantung pada Mahasiswa (tabel induk). Jika mahasiswa tersebut keluar (data dihapus), log bimbingan individu tersebut biasanya tidak perlu lagi disimpan dalam sistem operasional.
•	ON DELETE SET NULL
•	Kapan: Gunakan saat Anda ingin mempertahankan data meskipun induknya sudah dihapus, atau saat relasi bersifat opsional.
•	Contoh: Jika Anda menghapus seorang Dosen, Anda mungkin ingin tetap menyimpan catatan Monitoring_TA yang pernah dikelola dosen tersebut, namun set kolom NIDN_Pembimbing menjadi NULL sebagai penanda bahwa data dosen tersebut sudah tidak ada/tidak aktif lagi.
•	ON DELETE NO ACTION (Default)
•	Kapan: Gunakan pada data yang sangat kritikal atau sensitif, di mana penghapusan data tidak boleh dilakukan secara ceroboh atau tidak sengaja.
•	Contoh: Tabel Mahasiswa dan Monitoring_TA. Anda tidak boleh membiarkan sistem menghapus mahasiswa jika mereka masih memiliki status Tugas Akhir yang sedang berjalan. Anda "memaksa" admin untuk menyelesaikan urusan administrasi (misal: memindahkan ke arsip atau mengubah status TA) sebelum data mahasiswa bisa dihapus.

2.Dampaknya Terhadap Konsistensi Data
•	CASCADE: Menjaga konsistensi dengan cara pembersihan otomatis. Dampaknya, database bersih dari data "sampah" (data yatim/orphaned records), namun risiko kehilangan data sangat tinggi karena satu aksi hapus bisa berdampak beruntun ke banyak tabel.
•	SET NULL: Menjaga konsistensi dengan memutuskan ketergantungan. Data tetap ada, namun relasi (integritas) hilang. Ini bisa menyebabkan bug di aplikasi jika pengembang lupa menangani nilai NULL di kolom tersebut.
•	NO ACTION: Menjaga konsistensi dengan pencegahan (preventif). Ini adalah cara paling aman untuk memastikan bahwa hubungan antar tabel selalu valid dan tidak ada referensi yang menggantung ke data yang sudah tidak ada.

3.Risiko jika salah memilih:
- CASCADE    :Data Loss (Kehilangan Data): Anda menghapus satu user, namun secara tidak sengaja menghapus seluruh riwayat transaksi atau arsip penting yang seharusnya tetap ada.
- NO ACTION  :Operational Bottleneck: Anda akan kesulitan melakukan pembersihan database secara massal. Jika Anda ingin melakukan database housekeeping (menghapus data lama), Anda akan terhambat oleh error integritas terus-menerus.
- SET NULL   :Data Inconsistency: Anda akan memiliki baris data yang "buta" karena tidak lagi tahu siapa induknya. Contoh: Monitoring_TA tanpa Nim mahasiswa. Ini bisa merusak laporan statistik akademik.
*/




-- ================================================================
-- BAGIAN D – KEAMANAN 1: AUTENTIKASI & SERVER ROLES 
-- ================================================================

-- ===========================================
-- Soal 7 – Login dan Authentication 
-- ===========================================
USE master;
GO

-- 1. Login dengan Windows Authentication Tidak Dibutuhkan Lagi Karena Sudah Ada sebelumnya
CREATE LOGIN [rassya\legion] FROM WINDOWS;
GO

-- 2. Login dengan SQL Server Authentication
CREATE LOGIN LoginDosen WITH PASSWORD = 'Dosen123!';
GO

-- Membuat login untuk Staf Akademik (SQL Server Authentication)
CREATE LOGIN LoginStaf WITH PASSWORD = 'PasswordStaf123!';
GO

-- Membuat login untuk Operator (SQL Server Authentication)
CREATE LOGIN LoginOperator WITH PASSWORD = 'PasswordOperator123!';
GO

-- Membuat login untuk Auditor (SQL Server Authentication)
CREATE LOGIN LoginAuditor WITH PASSWORD = 'PasswordAuditor123!';
GO

-- Kebijakan Password
ALTER LOGIN LoginDosen WITH 
    CHECK_POLICY = ON,          -- Memaksa aturan password kompleks (min 8 char, simbol, angka)
    CHECK_EXPIRATION = ON;      -- Memaksa user ganti password secara berkala

-- Default Database
ALTER LOGIN LoginDosen
WITH DEFAULT_DATABASE = D_Monitoring_TA;

-- Status Login
-- Menonaktifkan login
ALTER LOGIN LoginDosen DISABLE;

-- Mengaktifkan kembali login
ALTER LOGIN LoginDosen ENABLE;

/*
1. Perbedaan Utama
| Fitur                | Windows Authentication                                            | SQL Server Authentication                                    |
| -------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------ |
| Identitas            | Menggunakan akun Windows atau Active Directory.                   | Menggunakan username dan password yang dibuat di SQL Server. |
| Penyimpanan          | Dikelola oleh sistem operasi Windows atau Active Directory.       | Dikelola langsung oleh SQL Server.                           |
| Keamanan             | Menggunakan protokol keamanan Windows seperti Kerberos atau NTLM. | Menggunakan mekanisme autentikasi internal SQL Server.       |
| Pengelolaan Password | Mengikuti kebijakan password Windows.                             | Dikelola secara manual oleh administrator SQL Server.        |
| Koneksi              | Cocok untuk lingkungan jaringan internal organisasi.              | Cocok untuk aplikasi yang diakses dari berbagai lokasi.      |

2. Kelebihan dan Kekurangan
- Windows Authentication
**Kelebihan:**
* Tingkat keamanan lebih tinggi karena terintegrasi dengan sistem keamanan Windows.
* Tidak perlu mengingat username dan password tambahan.
* Mendukung kebijakan password Windows secara otomatis.
* Mengurangi risiko pencurian password karena menggunakan mekanisme autentikasi yang lebih aman.

**Kekurangan:**
* Bergantung pada sistem operasi Windows atau Active Directory.
* Kurang fleksibel untuk pengguna dari luar jaringan organisasi.
* Tidak cocok untuk semua jenis aplikasi yang diakses melalui internet.

- SQL Server Authentication
**Kelebihan:**
* Dapat digunakan dari berbagai platform dan sistem operasi.
* Cocok untuk aplikasi web, mobile, dan cloud.
* Tidak memerlukan akun Windows atau Active Directory.
* Lebih fleksibel untuk pengguna eksternal.

**Kekurangan:**
* Keamanan sangat bergantung pada kekuatan password yang digunakan.
* Administrator harus mengelola akun dan password secara manual.
* Lebih rentan terhadap serangan brute force jika konfigurasi keamanan kurang baik.

3. Metode yang Cocok untuk Sistem Monitoring Tugas Akhir
Untuk sistem Monitoring Tugas Akhir (TA), metode yang paling sesuai adalah pendekatan Hybrid (kombinasi antara Windows Authentication dan SQL Server Authentication).

### Penggunaan Windows Authentication
Digunakan untuk:
* Administrator Database
* Staf Akademik
* Operator Sistem
Alasan:
* Bekerja di lingkungan kampus yang terhubung ke jaringan internal.
* Membutuhkan tingkat keamanan yang tinggi.
* Memudahkan pengelolaan hak akses melalui akun Windows.

### Penggunaan SQL Server Authentication
Digunakan untuk:
* Dosen
* Mahasiswa
Alasan:
* Dapat mengakses sistem dari luar kampus melalui aplikasi web atau internet.
* Tidak memerlukan akun Windows kampus.
* Lebih fleksibel untuk kebutuhan akses jarak jauh.

### Kesimpulan
Pendekatan Hybrid memberikan keseimbangan antara keamanan dan fleksibilitas. Windows Authentication digunakan untuk pengguna internal yang membutuhkan keamanan tinggi, sedangkan SQL Server Authentication digunakan untuk pengguna eksternal seperti dosen dan mahasiswa yang membutuhkan akses dari berbagai lokasi.
*/



-- ===========================================
-- Soal 8 – Fixed Server Roles 
-- ===========================================
-- 1. Memberikan akses Admin
ALTER SERVER ROLE sysadmin ADD MEMBER [rassya\legion];

-- 2. Memberikan akses Auditor
ALTER SERVER ROLE setupadmin ADD MEMBER AuditorUser;

-- 3. Memberikan akses Developer
ALTER SERVER ROLE dbcreator ADD MEMBER DevUser;
/*
# Soal 8 – Fixed Server Roles

## 1. Jenis Fixed Server Role yang Sesuai

### Administrator Database

Role yang sesuai: **sysadmin**

### Auditor Sistem

Role yang sesuai: **securityadmin**

### Developer atau Pengembang Database

Role yang sesuai: **dbcreator**

### Operator Backup Database

Role yang sesuai: **dbcreator** atau **sysadmin** (sesuai kebutuhan organisasi)

---

## 2. Alasan Pemberian Role Tersebut

### sysadmin

Role ini diberikan kepada Administrator Database karena memiliki hak akses penuh terhadap seluruh instance SQL Server. Administrator bertanggung jawab mengelola database, keamanan, backup, recovery, serta konfigurasi server.

### securityadmin

Role ini diberikan kepada Auditor atau petugas keamanan sistem karena dapat mengelola login dan memantau hak akses pengguna tanpa harus memiliki akses penuh terhadap seluruh database.

### dbcreator

Role ini diberikan kepada Developer karena memungkinkan pembuatan, perubahan, dan penghapusan database tanpa memberikan hak administrasi penuh terhadap server.

### Operator Backup

Role ini diberikan agar pengguna dapat membantu proses pengelolaan database sesuai tugasnya tanpa memperoleh hak akses yang berlebihan.

---

## 3. Risiko Jika Role Diberikan Terlalu Tinggi

### Risiko Pemberian Role sysadmin kepada Pengguna Biasa

* Pengguna dapat menghapus database secara sengaja maupun tidak sengaja.
* Pengguna dapat mengubah konfigurasi server yang dapat mengganggu layanan.
* Pengguna dapat melihat, mengubah, atau menghapus seluruh data dalam sistem.
* Pengguna dapat membuat akun baru dengan hak akses penuh.
* Pengguna dapat menonaktifkan fitur keamanan dan audit.

### Dampak

* Kehilangan data penting.
* Kebocoran data akademik mahasiswa dan dosen.
* Gangguan operasional sistem Monitoring Tugas Akhir.
* Penurunan integritas dan keamanan database.

---

## 4. Contoh Kasus Penyalahgunaan Hak Akses

### Kasus 1: Penghapusan Database

Seorang staf biasa diberikan role sysadmin. Karena kesalahan penggunaan perintah SQL, staf tersebut menjalankan perintah:

DROP DATABASE D_Monitoring_TA;

Akibatnya seluruh database Monitoring Tugas Akhir terhapus dan sistem tidak dapat digunakan.

### Kasus 2: Manipulasi Data Akademik

Pengguna dengan hak akses terlalu tinggi mengubah data pada tabel Mahasiswa atau Monitoring_TA sehingga informasi tugas akhir menjadi tidak valid.

### Kasus 3: Pembuatan Akun Tidak Sah

Pengguna yang memiliki hak securityadmin membuat akun login baru tanpa izin dan memberikan hak akses tinggi kepada akun tersebut sehingga berpotensi digunakan untuk mengakses data secara ilegal.

### Kasus 4: Kebocoran Data

Pengguna yang memiliki akses penuh menyalin data mahasiswa, dosen, dan proses tugas akhir kemudian menyebarkannya kepada pihak yang tidak berwenang sehingga melanggar keamanan informasi.

## Kesimpulan

Pemberian fixed server role harus mengikuti prinsip Least Privilege, yaitu setiap pengguna hanya diberikan hak akses sesuai tugas dan tanggung jawabnya. Dengan demikian keamanan, integritas, dan ketersediaan data pada sistem Monitoring Tugas Akhir dapat tetap terjaga.
*/



-- ================================================================
-- BAGIAN E – KEAMANAN 2: OTORISASI & USER MAPPING  
-- ================================================================

-- ===========================================
-- Soal 9 – User Database dan Mapping 
-- ===========================================
USE D_Monitoring_TA;
GO

-- Membuat User Database dari Login yang sudah ada
CREATE USER User_Staf_Akademik FOR LOGIN LoginStaf;
CREATE USER User_Operator_TA FOR LOGIN LoginOperator;
CREATE USER User_Auditor_Internal FOR LOGIN LoginAuditor;
GO

-- Memberikan hak akses spesifik ke tiap User (Mapping)
-- Staf Akademik: Full control di schema akademik
GRANT CONTROL ON SCHEMA::akademik TO User_Staf_Akademik;
GO

-- Operator: CRUD di schema aktivitas
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::aktivitas TO User_Operator_TA;
GO

-- Auditor: Read-only untuk seluruh database
GRANT SELECT ON SCHEMA::akademik TO User_Auditor_Internal;
GRANT SELECT ON SCHEMA::aktivitas TO User_Auditor_Internal;
GRANT SELECT ON SCHEMA::arsip TO User_Auditor_Internal;
GO

-- Membuat Role
CREATE ROLE Role_Akademik_Manager;
CREATE ROLE Role_TA_Operator;
CREATE ROLE Role_Sistem_Auditor;
GO

-- Memberikan Hak Akses (Izin) ke Role
-- Role_Akademik_Manager: Akses penuh pada schema akademik
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::akademik TO Role_Akademik_Manager;
GO

-- Role_TA_Operator: Akses penuh pada schema aktivitas (proses TA)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::aktivitas TO Role_TA_Operator;
GO

-- Role_Sistem_Auditor: Akses baca saja (Read-Only) pada seluruh database
GRANT SELECT ON SCHEMA::akademik TO Role_Sistem_Auditor;
GRANT SELECT ON SCHEMA::aktivitas TO Role_Sistem_Auditor;
GRANT SELECT ON SCHEMA::arsip TO Role_Sistem_Auditor;
GO

-- Memasukkan User ke dalam Role yang sesuai
ALTER ROLE Role_Akademik_Manager ADD MEMBER User_Staf_Akademik;
ALTER ROLE Role_TA_Operator ADD MEMBER User_Operator_TA;
ALTER ROLE Role_Sistem_Auditor ADD MEMBER User_Auditor_Internal;
GO

-- Menentukan Default Schema
-- Mengatur Default Schema untuk setiap User
ALTER USER User_Staf_Akademik WITH DEFAULT_SCHEMA = akademik;
ALTER USER User_Operator_TA WITH DEFAULT_SCHEMA = aktivitas;
ALTER USER User_Auditor_Internal WITH DEFAULT_SCHEMA = akademik; 
GO

-- VERIFIKASI Cek User Mapping di Database
SELECT dp.name AS UserName, dr.name AS RoleName
FROM sys.database_role_members drm
    JOIN sys.database_principals dp 
        ON drm.member_principal_id = dp.principal_id
    JOIN sys.database_principals dr 
        ON drm.role_principal_id = dr.principal_id;
GO
/*
# Soal 9 – User Database dan Mapping

## 1. Perbedaan Login dan User

### Login

Login merupakan akun yang digunakan untuk melakukan autentikasi ke SQL Server. Login bekerja pada tingkat server (server level) dan menentukan apakah seseorang diperbolehkan masuk ke SQL Server atau tidak.

Fungsi Login:

* Memverifikasi identitas pengguna.
* Mengontrol akses ke instance SQL Server.
* Menjadi penghubung antara pengguna dan database.

Contoh:

* LoginStaf
* LoginOperator
* LoginAuditor

### User

User merupakan akun yang berada di dalam database tertentu dan digunakan untuk melakukan otorisasi terhadap objek database.

Fungsi User:

* Mengatur hak akses di dalam database.
* Mengontrol akses terhadap tabel, view, procedure, dan objek lainnya.
* Terhubung dengan Login yang telah dibuat sebelumnya.

Contoh:

* User_Staf_Akademik
* User_Operator_TA
* User_Auditor_Internal

### Kesimpulan

Login menentukan siapa yang dapat masuk ke SQL Server, sedangkan User menentukan apa yang dapat dilakukan setelah masuk ke dalam database.

---

## 2. Fungsi Database Role

Database Role adalah kumpulan hak akses (permissions) yang dapat diberikan kepada beberapa user sekaligus.

Fungsi Database Role:

* Mempermudah pengelolaan hak akses pengguna.
* Mengurangi pemberian izin satu per satu kepada setiap user.
* Menjaga konsistensi hak akses antar pengguna dengan tugas yang sama.
* Mendukung penerapan prinsip keamanan Least Privilege.

Contoh pada Sistem Monitoring TA:

### Role_Akademik_Manager

Berfungsi untuk mengelola data akademik seperti mahasiswa, dosen, dan staf akademik.

### Role_TA_Operator

Berfungsi untuk mengelola proses monitoring tugas akhir, log bimbingan, dan aktivitas pendadaran.

### Role_Sistem_Auditor

Berfungsi untuk melakukan pemeriksaan dan monitoring data tanpa memiliki hak untuk mengubah data.

Dengan adanya role, administrator cukup memberikan hak akses kepada role, kemudian memasukkan user ke dalam role tersebut.

---

## 3. Fungsi Schema dalam Keamanan Database

Schema merupakan wadah logis yang digunakan untuk mengelompokkan objek database seperti tabel, view, dan stored procedure.

Fungsi Schema dalam Keamanan Database:

### Memisahkan Objek Berdasarkan Fungsi

Objek database dapat dikelompokkan sesuai kebutuhan sehingga lebih terorganisir.

Contoh:

* Schema akademik berisi tabel mahasiswa, dosen, dan staf.
* Schema aktivitas berisi monitoring tugas akhir dan log bimbingan.
* Schema arsip berisi data arsip tugas akhir.

### Mempermudah Pengelolaan Hak Akses

Administrator dapat memberikan izin langsung kepada schema tanpa harus memberikan izin pada setiap tabel satu per satu.

Contoh:

* GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::aktivitas TO Role_TA_Operator

Dengan satu perintah tersebut, seluruh objek dalam schema aktivitas dapat diakses sesuai izin yang diberikan.

### Meningkatkan Keamanan

Schema membantu membatasi akses pengguna hanya pada area kerja yang menjadi tanggung jawabnya.

Contoh:

* Auditor hanya diberikan akses baca.
* Operator hanya dapat mengakses schema aktivitas.
* Staf akademik hanya dapat mengakses schema akademik.

### Mengurangi Risiko Kesalahan Akses

Pengguna tidak dapat mengakses objek di luar schema yang telah diberikan izin sehingga keamanan database lebih terjaga.

## Kesimpulan

Login digunakan untuk masuk ke SQL Server, User digunakan untuk mengakses database tertentu, Database Role digunakan untuk mengelola hak akses secara terpusat, dan Schema digunakan untuk mengelompokkan objek sekaligus mempermudah pengaturan keamanan pada database.

*/



-- ===========================================
-- Soal 10 – Grant, Deny, Revoke
-- ===========================================
-- 1. Pelaksanaan GRANT (Memberikan Izin)
-- Operator: Diberikan izin untuk menambah dan mengubah log bimbingan
GRANT INSERT, UPDATE ON SCHEMA::aktivitas TO Role_TA_Operator;
GO

-- Auditor: Diberikan izin untuk membaca data master mahasiswa dan dosen
GRANT SELECT ON SCHEMA::akademik TO Role_Sistem_Auditor;
GO

-- Staf Akademik: Diberikan izin penuh untuk mengelola master data
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::akademik TO Role_Akademik_Manager;
GO

-- 2. Pelaksanaan DENY (Menolak Izin Secara Mutlak)
-- Auditor: Auditor TIDAK BISA mengubah data apa pun (mencegah manipulasi)
DENY DELETE, INSERT, UPDATE ON SCHEMA::akademik TO Role_Sistem_Auditor;
GO

-- 3. Pelaksanaan REVOKE (Mencabut Izin)
REVOKE SELECT ON SCHEMA::arsip FROM Role_TA_Operator;
GO

REVOKE DELETE ON SCHEMA::aktivitas TO Role_TA_Operator;
GO

-- VERIFIKASI Cek daftar izin (Permissions) yang aktif
SELECT 
    class_desc, 
    permission_name, 
    state_desc, 
    pr.name AS grantee_name
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('Role_TA_Operator', 'Role_Sistem_Auditor');
GO

/*
# Soal 10 – GRANT, DENY, dan REVOKE

## 1. Perbedaan GRANT, DENY, dan REVOKE

### GRANT

GRANT digunakan untuk memberikan hak akses atau izin kepada user maupun role untuk melakukan operasi tertentu pada objek database.

Fungsi:

* Memberikan hak akses kepada pengguna.
* Mengizinkan pengguna melakukan operasi tertentu seperti SELECT, INSERT, UPDATE, atau DELETE.
* Digunakan untuk mengatur otorisasi sesuai tugas masing-masing pengguna.

Contoh:

* Memberikan izin membaca data mahasiswa kepada Auditor.
* Memberikan izin mengelola data monitoring TA kepada Operator.

---

### DENY

DENY digunakan untuk secara tegas melarang user atau role melakukan suatu operasi, meskipun sebelumnya telah memperoleh izin melalui GRANT.

Fungsi:

* Mencegah akses terhadap objek tertentu.
* Mengutamakan keamanan pada data sensitif.
* Mengalahkan hak akses yang diberikan melalui GRANT.

Contoh:

* Auditor diberikan hak SELECT tetapi dilarang melakukan INSERT, UPDATE, dan DELETE.

---

### REVOKE

REVOKE digunakan untuk mencabut izin yang sebelumnya diberikan melalui GRANT atau DENY.

Fungsi:

* Menghapus hak akses yang sudah diberikan.
* Mengembalikan hak akses ke kondisi standar.
* Digunakan ketika pengguna sudah tidak membutuhkan suatu izin.

Contoh:

* Mencabut hak DELETE yang sebelumnya diberikan kepada Operator.

---

## 2. Konflik Hak Akses yang Mungkin Terjadi

Konflik hak akses terjadi ketika seorang user memperoleh izin yang berbeda dari beberapa sumber, misalnya dari user langsung dan dari role yang dimilikinya.

### Contoh Kasus 1

User_Operator_TA tergabung dalam Role_TA_Operator.

Role_TA_Operator memiliki:

GRANT DELETE ON SCHEMA::aktivitas

Tetapi administrator memberikan:

DENY DELETE ON SCHEMA::aktivitas TO User_Operator_TA

Hasil:
User tetap tidak dapat melakukan DELETE karena DENY memiliki prioritas lebih tinggi daripada GRANT.

---

### Contoh Kasus 2

User memperoleh izin SELECT dari sebuah role.

Kemudian administrator menjalankan:

REVOKE SELECT

Hasil:
Hak SELECT yang berasal dari role tetap berlaku karena REVOKE hanya mencabut izin yang diberikan secara langsung.

---

### Prioritas Hak Akses SQL Server

Urutan prioritas hak akses adalah:

1. DENY
2. GRANT
3. Tidak memiliki izin

Dengan demikian, apabila DENY dan GRANT diberikan secara bersamaan, maka DENY akan selalu menang.

---

## 3. Dampak Jika User Diberikan Hak DELETE Tanpa Pembatasan

Memberikan hak DELETE tanpa pembatasan dapat menimbulkan berbagai risiko terhadap keamanan dan integritas data.

### Kehilangan Data Penting

User dapat menghapus data mahasiswa, dosen, monitoring tugas akhir, atau log bimbingan secara sengaja maupun tidak sengaja.

Dampak:

* Data tidak dapat digunakan kembali.
* Proses akademik menjadi terganggu.

---

### Kerusakan Integritas Data

Penghapusan data induk dapat menyebabkan data terkait menjadi tidak konsisten, terutama jika terdapat relasi antar tabel.

Dampak:

* Data menjadi tidak lengkap.
* Hubungan antar tabel menjadi rusak.

---

### Penyalahgunaan Hak Akses

User yang tidak bertanggung jawab dapat menghapus data untuk kepentingan pribadi atau untuk merusak sistem.

Dampak:

* Menurunkan kepercayaan terhadap sistem.
* Menyulitkan proses audit dan pelacakan data.

---

### Gangguan Operasional Sistem

Penghapusan data yang digunakan oleh aplikasi dapat menyebabkan error pada sistem Monitoring Tugas Akhir.

Dampak:

* Sistem tidak dapat menampilkan data yang diperlukan.
* Proses monitoring dan pendadaran menjadi terhambat.

---

### Meningkatkan Beban Recovery

Administrator harus melakukan proses restore dari backup untuk mengembalikan data yang terhapus.

Dampak:

* Membutuhkan waktu dan sumber daya tambahan.
* Berpotensi menyebabkan kehilangan data terbaru yang belum sempat dibackup.

---

## Kesimpulan

GRANT digunakan untuk memberikan izin, DENY digunakan untuk menolak izin secara mutlak, sedangkan REVOKE digunakan untuk mencabut izin yang telah diberikan. Konflik hak akses dapat terjadi ketika user memperoleh izin dari berbagai sumber, dan dalam SQL Server perintah DENY memiliki prioritas tertinggi. Oleh karena itu, pemberian hak DELETE harus dibatasi dan diawasi dengan baik agar tidak menyebabkan kehilangan data maupun gangguan terhadap sistem Monitoring Tugas Akhir.

*/