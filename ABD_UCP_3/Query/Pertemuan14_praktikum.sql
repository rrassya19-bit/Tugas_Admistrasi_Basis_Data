-- =============================================
-- PRAKTIKUM 11: Indeks dan Optimasi Query
-- =============================================
USE KampusPraktikum;
GO


-- =============================================
-- PRAKTIKUM 1 - Mengamati Query Tanpa Indeks
-- =============================================
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT * 
FROM Akademik.Mahasiswa 
WHERE NIM = '20250140001';
GO
-- Catat: CPU Time, Elapsed Time, Logical Reads di tab Messages



-- =============================================
-- PRAKTIKUM 2 - Mengidentifikasi Clustered Index
-- =============================================
EXEC sp_helpindex 'Akademik.Mahasiswa';
GO


-- =============================================
-- PRAKTIKUM 3 - Membuat Non-Clustered Index
-- =============================================
-- Membuat Non-Clustered Index berdasarkan Nama
CREATE NONCLUSTERED INDEX IX_Mahasiswa_Nama 
ON Akademik.Mahasiswa (Nama);
GO

-- Verifikasi indeks sudah dibuat
EXEC sp_helpindex 'Akademik.Mahasiswa';
GO

-- Uji
SELECT * 
FROM Akademik.Mahasiswa 
WHERE Nama = 'Andi';
GO


-- =============================================
-- PRAKTIKUM 4 - Analisis Execution Plan (WHERE NIM)
-- =============================================
-- Aktifkan Execution Plan (tekan Ctrl + M)
SELECT * 
FROM Akademik.Mahasiswa 
WHERE NIM = '20250140001';
GO


-- =============================================
-- PRAKTIKUM 5 - Optimasi Query ORDER BY
-- =============================================
-- Sebelum Index (akan lambat + Sort mahal)
SELECT * 
FROM Akademik.Mahasiswa 
ORDER BY Nama;
GO

-- Buat Index khusus untuk ORDER BY
CREATE NONCLUSTERED INDEX IX_Mahasiswa_Nama_Order 
ON Akademik.Mahasiswa (Nama);
GO

-- Jalankan kembali setelah index dibuat
SELECT * 
FROM Akademik.Mahasiswa 
ORDER BY Nama;
GO




