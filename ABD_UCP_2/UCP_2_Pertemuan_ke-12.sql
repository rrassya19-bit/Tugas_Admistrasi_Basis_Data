-- ============================================================
-- UCP 2 - ADMINISTRASI BASIS DATA
-- ============================================================


-- ============================================================
-- MATERI 7 - STRATEGI BACKUP DATA
-- Alur: Full Backup → Differential Backup → Simulasi DELETE → Restore
-- ============================================================

-- ============================================================
-- BAGIAN 1 - PERSIAPAN AWAL
-- ============================================================

USE D_Monitoring_TA;
GO

-- Verifikasi tabel Mahasiswa sudah ada dan berisi data
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- BAGIAN 2 - RECOVERY MODEL
-- ============================================================

-- Cek Recovery Model saat ini
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'D_Monitoring_TA';
GO

-- Ubah Recovery Model ke FULL
-- (WAJIB dilakukan sebelum Full Backup pertama)
ALTER DATABASE D_Monitoring_TA
SET RECOVERY FULL;
GO

-- Verifikasi Recovery Model sudah berubah ke FULL
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'D_Monitoring_TA';
GO


-- ============================================================
-- BAGIAN 3 - FULL BACKUP
-- ============================================================

-- Melakukan Full Backup
-- Catatan: Pastikan folder D:\BackupSQL\ sudah dibuat secara manual
BACKUP DATABASE D_Monitoring_TA
TO DISK = 'D:\BackupSQL\D_Monitoring_TA_Full.bak'
WITH FORMAT,
     INIT,
     NAME = 'Full Backup D_Monitoring_TA',
     STATS = 10;
GO

-- Verifikasi file backup berhasil dibuat
RESTORE HEADERONLY
FROM DISK = 'D:\BackupSQL\D_Monitoring_TA_Full.bak';
GO


-- ============================================================
-- BAGIAN 4 - PERUBAHAN DATA (SIMULASI HARI KE-2)
-- ============================================================

-- Menambahkan data mahasiswa baru setelah Full Backup
INSERT INTO akademik.Mahasiswa (Nim, Nama, Jurusan, Angkatan)
VALUES
    ('20250140200', 'Rizky Pratama', 'Teknologi Informasi', 2025),
    ('20250140201', 'Sinta Aulia', 'Teknologi Informasi', 2025);
GO

-- Verifikasi data sudah masuk
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- BAGIAN 5 - DIFFERENTIAL BACKUP
-- ============================================================

-- Differential Backup: hanya menyimpan perubahan sejak Full Backup terakhir
BACKUP DATABASE D_Monitoring_TA
TO DISK = 'D:\BackupSQL\D_Monitoring_TA_Diff.bak'
WITH DIFFERENTIAL,
     INIT,
     NAME = 'Differential Backup D_Monitoring_TA',
     STATS = 10;
GO

-- Verifikasi file Differential Backup
RESTORE HEADERONLY
FROM DISK = 'D:\BackupSQL\D_Monitoring_TA_Diff.bak';
GO


-- ============================================================
-- BAGIAN 6 - SIMULASI KERUSAKAN DATA (HUMAN ERROR)
-- ============================================================

-- Simulasi human error: menghapus semua data mahasiswa
DELETE FROM akademik.Mahasiswa;
GO

-- Verifikasi data sudah terhapus (hasil: 0 row)
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- BAGIAN 7 - PROSES RESTORE
-- ============================================================

USE master;
GO

-- Langkah 1: Set database ke Single User Mode
-- (Menutup semua koneksi aktif agar proses restore bisa berjalan)
ALTER DATABASE D_Monitoring_TA
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

-- Langkah 2: Restore Full Backup
-- NORECOVERY = database belum aktif, masih menunggu restore berikutnya
RESTORE DATABASE D_Monitoring_TA
FROM DISK = 'D:\BackupSQL\D_Monitoring_TA_Full.bak'
WITH NORECOVERY,
     REPLACE,
     STATS = 10;
GO

-- Langkah 3: Restore Differential Backup
-- RECOVERY = database diaktifkan kembali setelah restore selesai
RESTORE DATABASE D_Monitoring_TA
FROM DISK = 'D:\BackupSQL\D_Monitoring_TA_Diff.bak'
WITH RECOVERY,
     STATS = 10;
GO

-- Langkah 4: Kembalikan ke Multi User
ALTER DATABASE D_Monitoring_TA
SET MULTI_USER;
GO


-- ============================================================
-- BAGIAN 8 - VERIFIKASI HASIL RESTORE
-- ============================================================

USE D_Monitoring_TA;
GO

-- Cek data: seharusnya kembali seperti sebelum DELETE
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- MATERI 8 - TRANSACTION LOG BACKUP & POINT-IN-TIME RECOVERY
-- Alur: Full Backup → Insert → Log1 → Insert → Log2 → DELETE → Restore STOPAT
-- ============================================================

-- ============================================================
-- LANGKAH 1 - CEK & UBAH RECOVERY MODEL
-- ============================================================

USE master;
GO

-- Cek Recovery Model
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'D_Monitoring_TA';
GO

-- Pastikan sudah FULL (jika belum, ubah)
ALTER DATABASE D_Monitoring_TA
SET RECOVERY FULL;
GO


-- ============================================================
-- LANGKAH 2 - FULL BACKUP (DASAR LOG)
-- ============================================================

-- Full Backup wajib dilakukan sebelum Log Backup bisa berjalan
BACKUP DATABASE D_Monitoring_TA
TO DISK = 'D:\BackupSQL\D_Monitoring_TA_Full2.bak'
WITH INIT,
     STATS = 10;
GO


-- ============================================================
-- LANGKAH 3 - SIMULASI TRANSAKSI PERTAMA
-- ============================================================

USE D_Monitoring_TA;
GO

-- Tambah data mahasiswa baru (Transaksi 1)
INSERT INTO akademik.Mahasiswa (Nim, Nama, Jurusan, Angkatan)
VALUES ('20250140210', 'Fajar Nugroho', 'Teknologi Informasi', 2025);
GO

-- Verifikasi
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- LANGKAH 4 - LOG BACKUP PERTAMA
-- ============================================================

-- Log1 berisi semua perubahan setelah Full Backup
BACKUP LOG D_Monitoring_TA
TO DISK = 'D:\BackupSQL\D_Monitoring_TA_Log1.trn'
WITH INIT,
     STATS = 10;
GO


-- ============================================================
-- LANGKAH 5 - SIMULASI TRANSAKSI KEDUA
-- ============================================================

-- Tambah data mahasiswa baru (Transaksi 2)
INSERT INTO akademik.Mahasiswa (Nim, Nama, Jurusan, Angkatan)
VALUES ('20250140211', 'Laila Nur Hidayah', 'Teknologi Informasi', 2025);
GO

-- Verifikasi
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- LANGKAH 6 - LOG BACKUP KEDUA
-- ============================================================

-- Log2 berisi perubahan setelah Log Backup pertama
BACKUP LOG D_Monitoring_TA
TO DISK = 'D:\BackupSQL\D_Monitoring_TA_Log2.trn'
WITH INIT,
     STATS = 10;
GO


-- ============================================================
-- LANGKAH 7 - SIMULASI HUMAN ERROR
-- ============================================================

-- Catat waktu sebelum menjalankan DELETE ini!
-- Misal waktu DELETE terjadi: 2026-05-19 10:30:00

DELETE FROM akademik.Mahasiswa;
GO

-- Verifikasi data kosong (0 row)
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- LANGKAH 8 - RESTORE POINT-IN-TIME
-- ============================================================

USE master;
GO

-- Set ke Single User Mode
ALTER DATABASE D_Monitoring_TA
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

-- Step 1: Restore Full Backup (NORECOVERY = belum selesai)
RESTORE DATABASE D_Monitoring_TA
FROM DISK = 'D:\BackupSQL\D_Monitoring_TA_Full2.bak'
WITH NORECOVERY,
     REPLACE;
GO

-- Step 2: Restore Log1 (NORECOVERY = masih lanjut restore)
RESTORE LOG D_Monitoring_TA
FROM DISK = 'D:\BackupSQL\D_Monitoring_TA_Log1.trn'
WITH NORECOVERY;
GO

-- Step 3: Restore Log2 dengan STOPAT
-- Isi STOPAT dengan waktu SEBELUM DELETE terjadi
-- Sesuaikan timestamp berdasarkan catatan waktu DELETE Anda
RESTORE LOG D_Monitoring_TA
FROM DISK = 'D:\BackupSQL\D_Monitoring_TA_Log2.trn'
WITH STOPAT = '2026-05-19 10:29:00',  -- Waktu sebelum DELETE
     RECOVERY;
GO

-- Kembalikan ke Multi User
ALTER DATABASE D_Monitoring_TA
SET MULTI_USER;
GO


-- ============================================================
-- LANGKAH 9 - VERIFIKASI POINT-IN-TIME RECOVERY
-- ============================================================

USE D_Monitoring_TA;
GO

-- 1. Cek status database (harus ONLINE)
SELECT name, state_desc
FROM sys.databases
WHERE name = 'D_Monitoring_TA';
GO

-- 2. Cek progress restore (jika masih berjalan)
SELECT
    percent_complete,
    start_time,
    estimated_completion_time / 1000 AS estimasi_detik,
    command
FROM sys.dm_exec_requests
WHERE command LIKE 'RESTORE%';
GO

-- 3. Jika database masih RESTORING (Solusi Jika Restore Terlalu Lama), jalankan ini:
RESTORE DATABASE D_Monitoring_TA WITH RECOVERY;

-- 4. Cek isi tabel (data harus kembali sebelum DELETE)
SELECT * FROM akademik.Mahasiswa;
GO


-- ============================================================
-- MATERI 9 - PEMELIHARAAN DATABASE (MAINTENANCE)
-- Alur: Cek Index → Cek Fragmentasi → Insert Data Acak →
--       REORGANIZE → REBUILD → UPDATE STATISTICS → DBCC CHECKDB
-- ============================================================

-- ============================================================
-- BAGIAN 1 - IDENTIFIKASI INDEX EXISTING
-- ============================================================

USE D_Monitoring_TA;
GO

-- Cek struktur index pada tabel Mahasiswa
SELECT
    i.name AS  NamaIndex,
    i.type_desc,
    i.is_primary_key
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('akademik.Mahasiswa');
GO
-- Hasil: akan terlihat PK_Mahasiswa (Clustered Index pada Nim)


-- ============================================================
-- BAGIAN 2 - CEK FRAGMENTASI AWAL
-- ============================================================

SELECT
    OBJECT_NAME(object_id) AS NamaTabel,
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);
GO
-- Biasanya hasil awal masih 0–5% (fragmentasi rendah)


-- ============================================================
-- BAGIAN 3 - MEMBUAT FRAGMENTASI (5–30%)
-- ============================================================

-- Langkah 1: Backup data awal (opsional, untuk keamanan)
SELECT * INTO akademik.Mahasiswa_backup
FROM akademik.Mahasiswa;
GO

-- Langkah 2: Insert data acak sebanyak 3000 baris
-- agar terjadi page split dan fragmentasi meningkat

-- Mahasiswa
DECLARE @i INT = 1;

WHILE @i <= 3000
BEGIN
    INSERT INTO akademik.Mahasiswa (Nim, Nama, Jurusan, Angkatan)
    VALUES (
        RIGHT('00000000000' + CAST(ABS(CHECKSUM(NEWID())) % 99999999999 AS VARCHAR(11)), 11),
        'RandomNama' + CAST(@i AS VARCHAR(10)),
        'Teknologi Informasi',
        2024
    );
    
    SET @i = @i + 1;
END

-- Dosen
SET NOCOUNT ON; -- Penting agar lebih cepat

DECLARE @i INT = 1;

WHILE @i <= 500
BEGIN
    INSERT INTO akademik.Dosen (NIDN, Nama, Prodi, Email)
    VALUES (
        RIGHT('0000000000' + CAST(ABS(CHECKSUM(NEWID())) % 9999999999 AS VARCHAR(10)), 10),
        'Dr. ' + 'RandomDosen' + CAST(@i AS VARCHAR(10)),
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'Teknologi Informasi'
            WHEN 1 THEN 'Sistem Informasi'
            WHEN 2 THEN 'Teknik Komputer'
            WHEN 3 THEN 'Manajemen Informatika'
            ELSE 'Teknik Elektro' 
        END,
        'dosen' + CAST(@i AS VARCHAR(10)) + '@univ.ac.id'
    );
   
    SET @i = @i + 1;
END
GO

--log Bimbingan
SET NOCOUNT ON;

DECLARE @i INT = 1;
DECLARE @Nim CHAR(11);
DECLARE @NIDN CHAR(10);

WHILE @i <= 3000
BEGIN
    -- Ambil Nim dan NIDN secara acak dari tabel yang sudah ada
    SELECT TOP 1 @Nim = Nim 
    FROM akademik.Mahasiswa 
    ORDER BY CHECKSUM(NEWID());

    SELECT TOP 1 @NIDN = NIDN 
    FROM akademik.Dosen 
    ORDER BY CHECKSUM(NEWID());

    INSERT INTO akademik.Log_Bimbingan (Nim, NIDN, Tanggal, Materi, Status)
    VALUES (
        @Nim,
        @NIDN,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),  -- Tanggal acak 1 tahun ke belakang
        'Materi Bimbingan ' + CAST(@i AS VARCHAR(10)),
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Selesai'
            WHEN 1 THEN 'Dalam Proses'
            WHEN 2 THEN 'Batal'
            ELSE 'Pending'
        END
    );
    
    SET @i = @i + 1;
END
GO


-- Staff_TU
SET NOCOUNT ON;
DECLARE @i INT = 1;

WHILE @i <= 50
BEGIN
    INSERT INTO akademik.Staff_TU (NIP, Jabatan, Email)
    VALUES (
        '198' + RIGHT('000000000' + CAST(@i AS VARCHAR(10)), 9),  -- NIP contoh
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'Kepala TU'
            WHEN 1 THEN 'Staff Akademik'
            WHEN 2 THEN 'Staff Keuangan'
            WHEN 3 THEN 'Staff Administrasi'
            ELSE 'Koordinator TA' 
        END,
        'staff' + CAST(@i AS VARCHAR(10)) + '@univ.ac.id'
    );
    SET @i = @i + 1;
END
GO


-- Pengajuan_Pendadaran 
SET NOCOUNT ON;
DECLARE @i INT = 1;
DECLARE @ID_TA INT;
DECLARE @NIDN1 CHAR(10);
DECLARE @NIDN2 CHAR(10);

WHILE @i <= 3000
BEGIN
    -- Ambil data secara acak dari tabel yang sudah ada
    SELECT TOP 1 @ID_TA = ID_TA 
    FROM aktivitas.Monitoring_TA 
    ORDER BY CHECKSUM(NEWID());

    SELECT TOP 1 @NIDN1 = NIDN FROM akademik.Dosen ORDER BY CHECKSUM(NEWID());
    SELECT TOP 1 @NIDN2 = NIDN FROM akademik.Dosen 
    WHERE NIDN <> @NIDN1 
    ORDER BY CHECKSUM(NEWID());

    INSERT INTO akademik.Pengajuan_Pendadaran 
        (ID_TA, NIDN_Penguji1, NIDN_Penguji2, IPK, SKS_Lulus, 
         Tanggal_Pengajuan, Tanggal_Ujian, Ruangan, Status, Nilai, Catatan)
    VALUES (
        @ID_TA,
        @NIDN1,
        @NIDN2,
        ROUND(2.5 + (RAND() * 1.5), 2),                    -- IPK antara 2.50 - 4.00
        120 + ABS(CHECKSUM(NEWID())) % 20,                 -- SKS Lulus
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 180, GETDATE()),
        DATEADD(DAY, 30 + ABS(CHECKSUM(NEWID())) % 60, GETDATE()),
        'Ruang ' + CHAR(65 + ABS(CHECKSUM(NEWID())) % 10),
        CASE ABS(CHECKSUM(NEWID())) % 4 
            WHEN 0 THEN 'Approved' 
            WHEN 1 THEN 'Pending' 
            WHEN 2 THEN 'Ditolak' 
            ELSE 'Selesai' 
        END,
        CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'A' ELSE 'B' END,
        'Catatan pengajuan ke-' + CAST(@i AS VARCHAR(10))
    );
    
    SET @i = @i + 1;
END
GO

-- Monitoring_TA
SET NOCOUNT ON;
DECLARE @i INT = 1;
DECLARE @Nim CHAR(11);
DECLARE @NIDN CHAR(10);

WHILE @i <= 1500
BEGIN
    SELECT TOP 1 @Nim = Nim FROM akademik.Mahasiswa ORDER BY CHECKSUM(NEWID());
    SELECT TOP 1 @NIDN = NIDN FROM akademik.Dosen ORDER BY CHECKSUM(NEWID());

    INSERT INTO aktivitas.Monitoring_TA (Nim, NIDN_Pembimbing, Judul_TA, Status_TA)
    VALUES (
        @Nim,
        @NIDN,
        'Pengembangan Sistem ' + 
        CASE ABS(CHECKSUM(NEWID())) % 6
            WHEN 0 THEN 'Inventaris Barang'
            WHEN 1 THEN 'Absensi Mahasiswa'
            WHEN 2 THEN 'Monitoring TA'
            WHEN 3 THEN 'Penjadwalan Kuliah'
            WHEN 4 THEN 'Prediksi Nilai Mahasiswa'
            ELSE 'Aplikasi E-Learning' 
        END + ' Berbasis ' + 
        CASE ABS(CHECKSUM(NEWID())) % 3 WHEN 0 THEN 'Web' WHEN 1 THEN 'Mobile' ELSE 'Desktop' END,
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'Proposal'
            WHEN 1 THEN 'Sedang TA'
            WHEN 2 THEN 'Sidang'
            WHEN 3 THEN 'Lulus'
            ELSE 'Bimbingan' 
        END
    );
    SET @i = @i + 1;
END
GO

-- Arsip
SET NOCOUNT ON;
DECLARE @i INT = 1;
DECLARE @ID_TA INT;

WHILE @i <= 2000
BEGIN
    -- Ambil ID_TA secara acak dari tabel Monitoring_TA
    SELECT TOP 1 @ID_TA = ID_TA 
    FROM aktivitas.Monitoring_TA 
    ORDER BY CHECKSUM(NEWID());

    INSERT INTO arsip.Arsip_TA (ID_TA, Tanggal_Arsip)
    VALUES (
        @ID_TA,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 400, GETDATE())  -- Tanggal acak hingga ~1 tahun ke belakang
    );
    
    SET @i = @i + 1;
END
GO


-- Langkah 3: Cek fragmentasi setelah insert data acak
-- Target: fragmentasi naik ke 5–30% atau lebih
SELECT
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);
GO


-- ============================================================
-- BAGIAN 4 - REORGANIZE (Untuk Fragmentasi 5–30%)
-- ============================================================

-- Reorganize: merapikan halaman index secara online
ALTER INDEX ALL ON akademik.Mahasiswa
REORGANIZE;
GO

-- Cek kembali fragmentasi → harus turun
SELECT
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);
GO


-- ============================================================
-- BAGIAN 5 - REBUILD (Untuk Fragmentasi > 30%)
-- ============================================================

-- Rebuild: membangun ulang index dari awal (lebih optimal)
ALTER INDEX ALL ON akademik.Mahasiswa
REBUILD;
GO

-- Cek kembali fragmentasi → harus turun mendekati 0%
SELECT
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);
GO


-- ============================================================
-- BAGIAN 6 - UPDATE STATISTICS
-- ============================================================

-- Cari nama index / statistik pada tabel Mahasiswa
SELECT name
FROM sys.stats
WHERE object_id = OBJECT_ID('akademik.Mahasiswa');
GO

-- Lihat detail statistik (ganti nama index sesuai hasil query di atas)
-- Contoh: DBCC SHOW_STATISTICS ('akademik.Mahasiswa', 'PK__Mahasisw__...');
DBCC SHOW_STATISTICS ('akademik.Mahasiswa', 'PK__Mahasisw__C7DEC33858A49462');
GO

-- Update statistik pada tabel Mahasiswa saja
UPDATE STATISTICS akademik.Mahasiswa;
GO

-- Atau update statistik seluruh database sekaligus
EXEC sp_updatestats;
GO


-- ============================================================
-- BAGIAN 7 - DBCC CHECKDB (CEK INTEGRITAS DATABASE)
-- ============================================================

-- Cek integritas seluruh database D_Monitoring_TA
-- Jika tidak ada error → database sehat
DBCC CHECKDB ('D_Monitoring_TA') WITH NO_INFOMSGS;
GO