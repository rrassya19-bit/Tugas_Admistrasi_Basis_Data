-- =========================================
-- Indeks dan Optimasi Query pada SQL Server
-- =========================================

-- BAGIAN - A:
-- SOAL 1:
-- Langkah 1 — Aktifkan Statistik
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- Langkah 2 — Jalankan Query
SELECT *
FROM aktivitas.Log_Bimbingan
WHERE Nim = '20250140157';
GO

-- SOAL 2:
-- Mengidentifikasi Clustered Index yang sudah ada
EXEC sp_helpIndex 'aktivitas.Log_Bimbingan';

-- Buat Index:
CREATE NONCLUSTERED INDEX IDX_Log_Bimbingan_Nim
ON aktivitas.Log_Bimbingan(Nim);
GO

-- Uji Setelah Index Dibuat:
SELECT *
FROM aktivitas.Log_Bimbingan
WHERE Nim = '20250140157';
GO

-- Analisis Execution Plan
-- Langkah 1 — Aktifkan Execution Plan
-- Tekan Ctrl + M di SSMS (Include Actual Execution Plan)

-- Langkah 2 — Jalankan Query:
SELECT *
FROM aktivitas.Log_Bimbingan
WHERE Nim = '20250140157';
GO

-- Langkah 3: Amati tab Execution Plan
--	- Physical Operation : Clustered Index Scan
--  - Actual Rows Read   : 5001
--  - Seek Predicate     : Nim = '20250140157'

-- SEBELUM INDEX pada kolom Tanggal
-- (Aktifkan Ctrl+M terlebih dahulu)
SELECT *
FROM aktivitas.Log_Bimbingan
ORDER BY Tanggal;

-- =================================================================================================================

-- SOAL 3:
-- Buat Index untuk ORDER BY Tanggal:
CREATE NONCLUSTERED INDEX IDX_Log_Bimbingan_Tanggal
ON aktivitas.Log_Bimbingan(Tanggal);
GO

-- Jalankan Kembali setelah index dibuat:
SELECT *
FROM aktivitas.Log_Bimbingan
ORDER BY Tanggal;

-- =================================================================================================================

-- BAGIAN - B:
-- SOAL 4:
SELECT * FROM aktivitas.Log_Bimbingan;

SELECT * FROM aktivitas.Log_Bimbingan
ORDER BY Tanggal;

-- =================================================================================================================

-- SOAL 5:
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * FROM aktivitas.Log_Bimbingan;
GO 50

SELECT * FROM aktivitas.Log_Bimbingan
WHERE Status = 'Disetujui';

-- =================================================================================================================

-- SOAL 7:
-- Langkah 1: Pada Profiler, pilih Column Filters.

-- Langkah 2: Filter Duration > 1000000 (artinya lebih dari 1 detik, dalam microseconds).

-- Langkah 3: Jalankan query simulasi lambat ini di SSMS:
WAITFOR DELAY '00:00:03';

SELECT * FROM aktivitas.Log_Bimbingan;

-- Langkah 4: Amati hasil Profiler — query ini akan muncul dengan Duration sekitar 3000 ms (3 detik), menandakan query lambat (slow query).