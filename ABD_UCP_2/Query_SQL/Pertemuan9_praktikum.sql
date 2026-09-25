-- ============================================================
-- BAGIAN 1 - PERSIAPAN AWAL
-- ============================================================

-- Membuat DataBase DBKampus
CREATE DATABASE DBKampus;
GO

USE DBKampus;
GO

-- Membuat Schema Akademik
CREATE SCHEMA Akademik;
GO

-- Membuat Tabel Mahasiswa
CREATE TABLE Akademik.Mahasiswa (
    NIM VARCHAR(11) PRIMARY KEY,
    Nama VARCHAR(50),
    TanggalLahir DATE,
    Prodi VARCHAR(50),
    TahunMasuk INT
);
GO

-- Menambahkan Data Awal (2 Data)
INSERT INTO Akademik.Mahasiswa VALUES
('20250140001','Andi','2004-02-10','Teknologi Informasi',2025),
('20250140002','Siti','2003-05-12','Teknik Elektro',2025);
GO

-- Mengecek Isi Tabel
SELECT * FROM Akademik.Mahasiswa;
GO


-- ============================================================
-- BAGIAN 2 - RECOVERY MODEL
-- ============================================================

-- Verifikasi kondisi Awal Recovery Model Database
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'DBKampus';
GO

-- Mengubah Recovery Model Ke FULL
ALTER DATABASE DBKampus
SET RECOVERY FULL;
GO

-- Verifikasi bahwa Recovery Model Sudah berubah Ke FULL
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'DBKampus';
GO


-- ============================================================
-- BAGIAN 3 - FULL BACKUP
-- ============================================================

-- Melakukan FULL BACKUP
BACKUP DATABASE DBKampus
TO DISK = 'D:\BackupSQL\DBKampus_Full.bak'
WITH FORMAT,
     INIT,
     NAME = 'Full Backup DBKampus',
     STATS = 10;
GO

-- Melihat informasi file backup (untuk memastikan backup berhasil)
RESTORE HEADERONLY
FROM DISK = 'D:\BackupSQL\DBKampus_Full.bak';
GO


-- ============================================================
-- BAGIAN 4 - PERUBAHAN DATA
-- ============================================================

-- Menambahkan data baru (simulasi hari ke-2)
INSERT INTO Akademik.Mahasiswa VALUES
('20250140003','Budi','2004-08-15','Teknologi Informasi',2025),
('20250140004','Dewi','2003-11-21','Teknik Mesin',2025);
GO

-- Verifikasi Data
SELECT * FROM Akademik.Mahasiswa;
GO


-- ============================================================
-- BAGIAN 5 - DIFFERENTIAL BACKUP 
-- ============================================================

-- Backup Hanya Perubahan Sejak FULL BACKUP Terakhir
BACKUP DATABASE DBKampus
TO DISK = 'D:\BackupSQL\DBKampus_Diff.bak'
WITH DIFFERENTIAL,
INIT,
NAME = 'Differential Backup DBKampus',
STATS = 10;
GO

-- Verifikasi File Differential Backup
RESTORE HEADERONLY
FROM DISK = 'D:\BackupSQL\DBKampus_Diff.bak';
GO
-- (Note: DiAerential hanya menyimpan perubahan sejak Full Back up terakhir.)


-- ============================================================
-- BAGIAN 6 - SIMULASI ERROR KERUSAKAN DATA
-- ============================================================

-- Menghapus Semua Data (Simulasi Human Error)
DELETE FROM Akademik.Mahasiswa;
GO

-- Verifikasi Data Hilang
SELECT * FROM Akademik.Mahasiswa;
GO


-- ============================================================
-- BAGIAN 7 - PROSES RESTORE
-- ============================================================

USE master;
GO
-- Set Database ke Single User Mode (Menutup semua koneksi ke database biar bisa restore)
ALTER DATABASE DBKampus
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

-- Restore Full Backup (NORECOVERY = database belum aktif karena masih lanjut restore)
RESTORE DATABASE DBKampus
FROM DISK = 'D:\BackupSQL\DBKampus_Full.bak'
WITH NORECOVERY,
     REPLACE,
     STATS = 10;
GO

--  Restore Differential Backup (RECOVERY = database diaktifkan kembali)
RESTORE DATABASE DBKampus
FROM DISK = 'D:\BackupSQL\DBKampus_Diff.bak'
     WITH RECOVERY,
     STATS = 10;
GO

-- Kembalikan ke Multi User Agar Bisa Digunakan Banyak User
ALTER DATABASE DBKampus
SET MULTI_USER;
GO


-- ============================================================
-- BAGIAN 8 - VERIFIKASI
-- ============================================================

USE DBKampus;
GO

-- Cek Data
SELECT * FROM Akademik.Mahasiswa;
GO