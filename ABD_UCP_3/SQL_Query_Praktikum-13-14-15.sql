
-- ====================================
-- SQL Server Agent & Otomasi Pekerjaan 
-- ====================================

-- PRAKTIKUM 1 — Mengaktifkan SQL Server Agent
--	1. Buka SQL Server Management Studio (SSMS), connect ke server kamu.
--	2. Di Object Explorer, cari node SQL Server Agent (di bawah node database kamu).
--	3. Klik kanan → Start.
--	4. Kalau berhasil, akan muncul ikon hijau dan tulisan SQL Server Agent (Running).

-- =========================================================================================================

-- PRAKTIKUM 2 — Membuat Job Backup
--	1. Klik SQL Server Agent → klik kanan Jobs → New Job.
--	2. Tab General, isi Name: Backup_Harian_MonitoringTA
--	3. Tab Steps → New, isi:
--		- Step name: Backup Database
--		- Type: Transact-SQL script (T-SQL)
--		- Database: pilih NamaDatabaseAnda		  
		BACKUP DATABASE [D_Monitoring_TA]
		TO DISK = 'D:\BackupSQL\MonitoringTA_Full.bak'
		WITH FORMAT,
		MEDIANAME = 'BackupDB',
		NAME = 'Full Backup MonitoringTA';
		GO

-- ==========================================================================================================

-- PRAKTIKUM 3 — Membuat Schedule
--	1. Masih di New Job, masuk tab Schedules → New.
--	2. Isi:
--		- Name: Backup_Malam
--		- Schedule type: Recurring
--		- Frequency (Occurs): Daily
--		- Daily frequency: Occurs once at → 23:00:00
--	3. Klik OK, lalu OK lagi untuk menyimpan Job.
--	4. Hasil: backup NamaDatabaseAnda jalan otomatis tiap malam jam 23:00.	 

-- ==========================================================================================================

-- PRAKTIKUM 4 — Maintenance Job (Rebuild Index)
--	Studi kasus: tabel aktivitas.Log_Bimbingan akan sering di-insert (apalagi kalau nanti diisi ribuan data), 
--	jadi index bisa fragmentasi dan query jadi lambat. Admin ingin rebuild index otomatis tiap minggu.
--	1. SQL Server Agent → Jobs → New Job. Name: Rebuild_Index_MonitoringTA
--	2. Tab Steps → New. Database: NamaDatabaseAnda. Command:
		EXEC sp_MSforeachtable
		'ALTER INDEX ALL ON ? REBUILD';
		GO
--  3. Tab Schedules → New: Frequency Weekly, jam 01:00:00.

-- ==========================================================================================================

-- PRAKTIKUM 5 — Membuat Operator
--	Tujuan: operator menerima notifikasi email kalau job gagal.

--	1. SQL Server Agent → klik kanan Operators → New Operator.
--	2. Isi:
--		- Name: Admin_MonitoringTA
--		- E-mail name: (rrassya19@gmail.com)
--	3. Klik OK untuk menyimpan.

-- ==========================================================================================================

-- PRAKTIKUM 6 — Alert Kegagalan Backup
--	Studi kasus: kalau job backup di Praktikum 2 gagal, sistem harus otomatis kirim email ke Admin_MonitoringTA.

--	1. SQL Server Agent → klik kanan Alerts → New Alert.
--	2. Tab General:
--		- Name: Alert_Backup_Gagal
--		- Type: SQL Server event alert
--		- Database name: pilih NamaDatabaseAnda
--		- Error number: 3013
--	3. Tab Response: centang Notify operators → centang E-mail untuk Admin_MonitoringTA.
--	4. Klik OK.
--	5. Untuk test: jalankan job backup dengan path yang sengaja salah (misal folder tidak ada) supaya gagal, lalu cek apakah alert kepicu — ini juga bagus untuk screenshot bukti kerja di laporan.

-- ==========================================================================================================



-- =========================================
-- Indeks dan Optimasi Query pada SQL Server
-- =========================================
USE D_Monitoring_TA;

-- PRAKTIKUM 1 — Mengamati Query Tanpa Indeks 
-- Langkah 1 — Aktifkan Statistik
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- Langkah 2 — Jalankan Query
SELECT *
FROM aktivitas.Log_Bimbingan
WHERE Nim = '20250140157';
GO

-- Langkah 3 — Catat di tab Messages:
--	- CPU Time → berapa ms
--	- Elapsed Time → berapa ms
--	- Logical Reads → berapa pages (1 page = 8 KB)

-- ==========================================================================================================

-- PRAKTIKUM 2 — Mengidentifikasi Clustered Index
-- index_name = PK_Log_Bimbingan
-- index_description = clustered, unique, primary key...
-- index_keys = ID_Log
EXEC sp_helpIndex 'aktivitas.Log_Bimbingan';

-- ==========================================================================================================

-- PRAKTIKUM 3 — Membuat Non-Clustered Index
-- Studi Kasus: Bagian akademik sering mencari log bimbingan berdasarkan Nim mahasiswa
-- Sebelum index = ... reads
-- Sesudah index = ... reads (harusnya lebih kecil)

-- Buat Index:
CREATE NONCLUSTERED INDEX IDX_Log_Bimbingan_Nim
ON aktivitas.Log_Bimbingan(Nim);
GO

-- Uji Setelah Index Dibuat:
SELECT *
FROM aktivitas.Log_Bimbingan
WHERE Nim = '20250140157';
GO

-- ==========================================================================================================

-- PRAKTIKUM 4 — Analisis Execution Plan
-- Physical Operation = Clustered Index Scan / Seek
-- Actual Rows Read = angkanya
-- Estimated Operator Cost = angkanya
-- Ordered = True / False
-- Predicate / Seek Predicate = kondisi WHERE-nya

-- Langkah 1 — Aktifkan Execution Plan
-- Tekan Ctrl + M di SSMS (Include Actual Execution Plan)

-- Langkah 2 — Jalankan Query:
SELECT *
FROM aktivitas.Log_Bimbingan
WHERE Nim = '20250140157';
GO

-- Langkah 3: Amati tab Execution Plan
--	- Physical Operation : Nonclustered Index Seek
--  - Actual Rows Read   : 1
--  - Seek Predicate     : Nim = '20250140157'

-- HASIL ANALISIS

-- CLUSTERED INDEX SCAN
-- SQL Server menggunakan Clustered Index Scan, yang menunjukkan
-- bahwa SQL Server memindai seluruh isi clustered index
-- (PK_Log_Bimbingan) untuk menemukan data yang dicari.
-- Berbeda dengan Index Seek, Scan membaca semua baris
-- satu per satu hingga menemukan yang sesuai.

-- ACTUAL NUMBER OF ROWS READ = 1
-- SQL Server hanya menemukan 1 baris data yang memenuhi kondisi
-- WHERE Nim = '20250140157', namun tetap harus memindai
-- seluruh tabel untuk menemukannya.

-- ACTUAL NUMBER OF ROWS FOR ALL EXECUTIONS = 1
-- Jumlah record yang dikembalikan oleh query adalah 1 baris.

-- ESTIMATED NUMBER OF ROWS TO BE READ = 1
-- Estimator SQL Server memperkirakan hanya perlu membaca 1 baris,
-- dan hasil aktual juga 1 baris, sehingga menunjukkan
-- statistik database yang cukup akurat.

-- ESTIMATED OPERATOR COST = 0.0032831 (100%)
-- Biaya eksekusi query sangat kecil karena data dalam tabel
-- masih sedikit, namun persentase 100% menunjukkan tidak ada
-- operasi lain yang membantu, seluruh beban ditanggung
-- oleh operasi scan ini.

-- ORDERED = FALSE
-- Data tidak dibaca dalam urutan tertentu. Ini adalah ciri khas
-- Scan, berbeda dengan Seek yang bersifat ordered. Artinya
-- SQL Server tidak dapat memanfaatkan urutan index
-- untuk mempercepat pencarian.

-- OBJECT
-- SQL Server menggunakan index PK_Log_Bimbingan yang merupakan
-- Clustered Index berbasis kolom ID_Log (Primary Key).
-- Karena pencarian dilakukan pada kolom Nim yang bukan bagian
-- dari clustered index key, SQL Server terpaksa melakukan scan.

-- PREDICATE
-- Pencarian dilakukan dengan kondisi:
-- [aktivitas].[Log_Bimbingan].[Nim] = '20250140157'
-- Karena kolom Nim belum memiliki Non-Clustered Index,
-- SQL Server menggunakan Predicate (filter setelah scan)
-- bukan Seek Predicate (langsung menuju data).


-- KESIMPULAN
-- Berdasarkan Execution Plan, query menggunakan Clustered Index
-- Scan pada tabel aktivitas.Log_Bimbingan karena kolom Nim
-- belum memiliki indeks tersendiri. SQL Server terpaksa memindai
-- seluruh tabel melalui Clustered Index (PK_Log_Bimbingan)
-- untuk menemukan baris yang sesuai. Meskipun hasil akhirnya
-- hanya 1 baris dan biaya saat ini masih kecil, pendekatan Scan
-- ini akan menjadi tidak efisien seiring bertambahnya jumlah data.
-- Solusinya adalah membuat Non-Clustered Index pada kolom Nim
-- agar SQL Server dapat langsung melakukan Index Seek
-- tanpa harus memindai seluruh tabel.

-- ==========================================================================================================

-- PRAKTIKUM 5 - Optimasi Query ORDER BY
-- Apakah ada node Sort yang hilang?
-- Cost % turun atau tidak?
-- Row Size berubah atau tidak?

-- SEBELUM INDEX pada kolom Tanggal
-- (Aktifkan Ctrl+M terlebih dahulu)
SELECT *
FROM aktivitas.Log_Bimbingan
ORDER BY Tanggal;

-- Buat Index untuk ORDER BY Tanggal:
CREATE NONCLUSTERED INDEX IDX_Log_Bimbingan_Tanggal
ON aktivitas.Log_Bimbingan(Tanggal);
GO

-- Jalankan Kembali setelah index dibuat:
SELECT *
FROM aktivitas.Log_Bimbingan
ORDER BY Tanggal;

-- ANALISIS SEBELUM INDEX (Gambar 1)
-- Operator: Clustered Index Scan (Clustered)
-- Node ID : 1

-- PHYSICAL & LOGICAL OPERATION = Clustered Index Scan
-- SQL Server memindai seluruh isi tabel melalui Clustered Index
-- PK_Log_Bimbingan karena kolom Tanggal belum memiliki indeks.
-- Seluruh data dibaca terlebih dahulu sebelum diurutkan.

-- ESTIMATED OPERATOR COST = 0.0032831 (22%)
-- Biaya operasi scan sebesar 22% dari total keseluruhan query.
-- Sisanya 78% digunakan oleh operasi Sort yang berjalan
-- secara terpisah untuk mengurutkan data berdasarkan Tanggal.

-- ORDERED = FALSE
-- Data tidak dibaca dalam urutan Tanggal. SQL Server harus
-- melakukan operasi Sort tambahan setelah scan selesai,
-- sehingga query membutuhkan dua tahap operasi.

-- ESTIMATED ROW SIZE = 4075 B
-- Ukuran baris yang dibaca sangat besar (4075 Byte) karena
-- mencakup semua kolom: ID_Log, Nim, NIDN, Tanggal,
-- Materi (nvarchar MAX), dan Status.

-- OUTPUT LIST (Sebelum Index)
-- Menghasilkan semua kolom:
-- ID_Log, Nim, NIDN, Tanggal, Materi, Status

-- ============================================================

-- ANALISIS SESUDAH INDEX 
-- Operator: Clustered Index Scan (Clustered)
-- Node ID : 2

-- PHYSICAL & LOGICAL OPERATION = Clustered Index Scan
-- SQL Server masih menggunakan Clustered Index Scan,
-- namun kini berjalan bersama Non-Clustered Index
-- IDX_Log_Bimbingan_Tanggal yang baru dibuat.

-- ESTIMATED OPERATOR COST = 0.0032831 (13%)
-- Biaya operasi turun dari 22% menjadi 13%. Penurunan ini
-- menunjukkan bahwa index Tanggal membantu SQL Server
-- membagi beban kerja sehingga lebih efisien.

-- ORDERED = FALSE
-- Data pada node ini masih dibaca tidak berurutan, namun
-- Non-Clustered Index pada Tanggal membantu SQL Server
-- menentukan urutan data lebih awal sebelum proses Sort.

-- ESTIMATED ROW SIZE = 14 B
-- Ukuran baris turun drastis dari 4075 B menjadi hanya 14 B.
-- Ini karena node ini hanya membaca kolom Tanggal dan ID_Log
-- dari Non-Clustered Index, tidak lagi membaca semua kolom.

-- OUTPUT LIST (Sesudah Index)
-- Hanya menghasilkan: ID_Log dan Tanggal
-- SQL Server memanfaatkan index untuk membaca kolom minimum
-- yang dibutuhkan terlebih dahulu sebelum Key Lookup.

-- TABEL PERBANDINGAN SEBELUM vs SESUDAH INDEX
-- +---------------------------+----------------+----------------+
-- | Aspek                     | Sebelum Index  | Sesudah Index  |
-- +---------------------------+----------------+----------------+
-- | Physical Operation        | CI Scan        | CI Scan        |
-- | Estimated Operator Cost   | 0.0032831 (22%)| 0.0032831 (13%)|
-- | Estimated Row Size        | 4075 B         | 14 B           |
-- | Output List               | Semua kolom    | ID_Log,Tanggal |
-- | Node ID                   | 1              | 2              |
-- | Ordered                   | False          | False          |
-- +---------------------------+----------------+----------------+

-- KESIMPULAN
-- Setelah membuat Non-Clustered Index IDX_Log_Bimbingan_Tanggal,
-- terjadi penurunan persentase biaya operasi dari 22% menjadi
-- 13%. SQL Server kini memanfaatkan index untuk membaca hanya
-- kolom yang diperlukan (ID_Log dan Tanggal) dengan ukuran baris
-- yang jauh lebih kecil (4075 B -> 14 B). Hal ini menunjukkan
-- bahwa index berhasil mengurangi beban pembacaan data.
-- Meskipun Physical Operation masih Clustered Index Scan,
-- penggunaan Non-Clustered Index pada kolom Tanggal terbukti
-- membantu SQL Server bekerja lebih efisien dalam menangani
-- query ORDER BY pada tabel aktivitas.Log_Bimbingan.

-- ==========================================================================================================

-- CLEANUP - Hapus index setelah praktikum (opsional)
DROP INDEX IDX_Log_Bimbingan_Nim ON aktivitas.Log_Bimbingan;
DROP INDEX IDX_Log_Bimbingan_Tanggal ON aktivitas.Log_Bimbingan;

-- ==========================================================================================================



-- =============================================================================================
-- Monitoring Performa SQL Server Menggunakan Activity Monitor, PerfMon, dan SQL Server Profiler 
-- =============================================================================================

-- PRAKTIKUM 1 — Monitoring dengan Activity Monitor
-- Langkah 1: Buka SSMS → Object Explorer → klik kanan nama server → Activity Monitor (atau Ctrl+Alt+A).

-- Langkah 2: 
-- Amati bagian Overview: 
--	- CPU Usage
--  - Waiting Tasks
--	- Database I/O

-- Langkah 3: Jalankan query berikut di SSMS:
SELECT * FROM aktivitas.Log_Bimbingan;

-- Langkah 4: Amati perubahan pada Activity Monitor, lalu catat hasilnya di tabel:
-- +---------------------------+----------------+
-- | Parameter                 | Nilai          | 
-- +---------------------------+----------------+
-- | CPU Usage                 |                | 
-- | Waiting Tasks             |                | 
-- | Database I/O              |                | 
-- | Batch Requests/sec        |                | 
-- +---------------------------+----------------+

-- ==========================================================================================================

-- PRAKTIKUM 2 — Recent Expensive Queries
-- Langkah 1: Buka Activity Monitor → Recent Expensive Queries.

-- Langkah 2: Jalankan query ini beberapa kali (klik Execute berulang):
SELECT * FROM aktivitas.Log_Bimbingan
ORDER BY Tanggal;

-- Langkah 3: Perhatikan kolom CPU, Duration, Logical Reads pada panel Recent Expensive Queries, lalu catat di tabel:
-- +------------------------------------------------------------+---------+---------------+
-- | Query                                                      | CPU     |  Duration     | 
-- +------------------------------------------------------------+---------+---------------+
-- | SELECT * FROM aktivitas.Log_Bimbingan ORDER BY Tanggal;    |         |               | 
-- +------------------------------------------------------------+---------+-----------=---+

-- ==========================================================================================================

-- PRAKTIKUM 3 - Monitoring CPU dan Memory Menggunakan PerfMon
-- Langkah 1: Tekan Windows + R, ketik Perfmon.

-- Langkah 2: Masuk ke Performance Monitor, klik tombol +.

-- Langkah 3: Tambahkan counter berikut satu per satu:
--	- Processor → % Processor Time (instance _Total)
--	- Memory → Available MBytes
--	- PhysicalDisk → Avg. Disk Queue Length (instance _Total)


-- Cek dulu apakah ID_Log itu IDENTITY (hasil harus 1)
SELECT is_identity 
FROM sys.columns 
WHERE object_id = OBJECT_ID('aktivitas.Log_Bimbingan') AND name = 'ID_Log';

-- Insert 5000 baris data dummy
INSERT INTO aktivitas.Log_Bimbingan (Nim, NIDN, Tanggal, Materi, Status)
SELECT 
    (SELECT TOP 1 Nim FROM master.Mahasiswa ORDER BY NEWID()) AS Nim,
    (SELECT TOP 1 NIDN FROM master.Dosen ORDER BY NEWID()) AS NIDN,
    CAST(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1260, '2023-01-01') AS DATE) AS Tanggal,
    (SELECT TOP 1 Materi FROM (VALUES 
        (N'Konsultasi Bab 1 - Pendahuluan'),
        (N'Revisi rumusan masalah penelitian'),
        (N'Pembahasan metodologi penelitian'),
        (N'Konsultasi Bab 2 - Tinjauan Pustaka'),
        (N'Review instrumen penelitian'),
        (N'Pembahasan hasil analisis data'),
        (N'Revisi Bab 4 - Hasil dan Pembahasan'),
        (N'Konsultasi kesimpulan dan saran'),
        (N'Persiapan sidang pendadaran'),
        (N'Revisi format penulisan skripsi')
    ) AS T(Materi) ORDER BY NEWID()) AS Materi,
    (SELECT TOP 1 Status FROM (VALUES ('Selesai'), ('Proses'), ('Revisi'), ('Disetujui')) AS S(Status) ORDER BY NEWID()) AS Status
FROM (
    SELECT TOP (5000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
) AS Angka;

-- Cek jumlah data setelah insert
SELECT COUNT(*) AS Total_Log_Bimbingan FROM aktivitas.Log_Bimbingan;

-- Hapus data dummy, sisain 1 data asli yang sudah ada sebelumnya (Cek dulu ID_Log dari data asli (biasanya yang paling kecil/lama))
SELECT TOP 5 * FROM aktivitas.Log_Bimbingan ORDER BY ID_Log ASC;

-- Setelah tahu ID_Log data asli (misal nilainya 1), hapus sisanya:
DELETE FROM aktivitas.Log_Bimbingan
WHERE ID_Log > 1;  -- ganti angka 1 sesuai ID_Log data asli yang mau disisakan

-- Cek ulang jumlah data setelah dihapus
SELECT COUNT(*) AS Total_Log_Bimbingan FROM aktivitas.Log_Bimbingan;

-- Langkah 4: Kembali ke SSMS, jalankan query ini berulang kali agar beban server terlihat di grafik PerfMon:
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * FROM aktivitas.Log_Bimbingan;
GO 50

-- Cek insert data
SELECT COUNT(*) AS TotalData FROM aktivitas.Log_Bimbingan;

-- ==========================================================================================================

-- PRAKTIKUM 4 — SQL Server Profiler
-- Langkah 1: Buka Tools → SQL Server Profiler.

-- Langkah 2: File → New Trace.

-- Langkah 3: Gunakan Template: Standard.

-- Langkah 4: Centang event SQL:BatchCompleted dan RPC:Completed.

-- Langkah 5: Klik Run.

-- Langkah 6: Kembali ke SSMS, jalankan:
SELECT * FROM aktivitas.Log_Bimbingan
WHERE Status = 'Disetujui';

-- Langkah 7: Amati pada Profiler: 
--	- query yang dieksekusi 
--	- Start Time 
--	- End Time
--	- Duration

-- ==========================================================================================================

-- PRAKTIKUM 5 — Mencari Query yang Lambat
-- Langkah 1: Pada Profiler, pilih Column Filters.

-- Langkah 2: Filter Duration > 1000000 (artinya lebih dari 1 detik, dalam microseconds).

-- Langkah 3: Jalankan query simulasi lambat ini di SSMS:
WAITFOR DELAY '00:00:03';

SELECT * FROM aktivitas.Log_Bimbingan;

-- Langkah 4: Amati hasil pada Profiler — query ini akan muncul dengan Duration sekitar 3000 ms (3 detik), menandakan query lambat (slow query).
