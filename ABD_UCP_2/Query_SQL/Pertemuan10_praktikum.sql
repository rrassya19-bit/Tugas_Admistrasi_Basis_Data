--LANGKAH 1 - СЕК & UBAH RECOVERY MODEL
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'KampusPraktikum';

ALTER DATABASE KampusPraktikum
SET RECOVERY FULL;
GO

--LANGKAH 2 - FULL BACKUP (DASAR LOG)
BACKUP DATABASE KampusPraktikum
TO DISK = 'D:\BackupSQL\KampusPraktikum_Full2.bak'
WITH INIT,
	STATS = 10;
GO

-- LANGKAH 3 - SIMULASI TRANSAKSI
INSERT INTO akademik.Mahasiswa (NIM, Nama, TanggalLahir, Prodi, TahunMasuk)
VALUES ('999', 'Simulasi1', '2004-04-11','Teknologi Informasi','2025');

-- LANGKAH 4 - LOG BACKUP PERTAMA
BACKUP LOG KampusPraktikum
TO DISK = 'D:\BackupSQL\KampusPraktikum_Log1.trn'
WITH INIT,
	STATS = 10;
GO

--LANGKAH 5 - TRANSAKSI KEDUA
INSERT INTO akademik.Mahasiswa (NIM, Nama, TanggalLahir,Prodi,TahunMasuk) 
VALUES ('998', 'Simulasi2', '2004-04-11','Teknologi Informasi','2025');

-- LANGKAH 6 - LOG BACKUP KEDUA
BACKUP LOG KampusPraktikum
TO DISK = 'D:\BackupSQL\KampusPraktikum_Log2.trn'
WITH INIT,
	STATS = 10;
GO

-- LANGKAH 7 - SIMULASI HUMAN ERROR
DELETE FROM akademik.Mahasiswa; 
GO

SELECT*FROM akademik.Mahasiswa;

-- LANGKAH 8 - RESTORE POINT-IN-TIME
--1. Restore Full Backup
/*Master*/
RESTORE DATABASE KampusPraktikum
FROM DISK = 'D:\BackupSQL\KampusPraktikum_Full2.bak'
WITH NORECOVERY,
	REPLACE;
GO

--2. Restore Log1
RESTORE LOG KampusPraktikum
FROM DISK = 'D:\BackupSQL\KampusPraktikum_Log1.trn'
WITH NORECOVERY;
GO

--3. Restore Log2 dengan STOPAT
RESTORE LOG KampusPraktikum
FROM DISK = 'D:\BackupSQL\KampusPraktikum_Log2.trn'
WITH STOPAT = '2026-05-06 18:40:00',
	RECOVERY;
GO

-- LANGKAH 9 - VERIFIKASI
-- 1. Cek status database
SELECT name, state_desc 
FROM sys.databases
WHERE name = 'KampusPraktikum';

-- 2. Cara Mengecek Progress Restore
SELECT
	percent_complete,
	start_time,
	estimated_completion_time/1000 AS estimasi_detik,
	command
FROM sys.dm_exec_requests
WHERE command LIKE 'RESTORE%';

-- 3. Solusi Jika Restore Terlalu Lama
RESTORE DATABASE KampusPraktikum WITH RECOVERY;