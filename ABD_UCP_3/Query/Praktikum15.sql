-- Jalankan Query Pemicu
SELECT * 
FROM Akademik.Mahasiswa;

-- Jalankan Query Berulang
SELECT *
FROM Akademik.Mahasiswa
ORDER BY Nama;

-- Jalankan Query Beban Tinggi
SELECT *
FROM Akademik.Mahasiswa;
GO 50

SELECT *
FROM Akademik.Mahasiswa
WHERE Prodi = 'Teknologi Informasi';

WAITFOR DELAY '00:00:03';

SELECT *
FROM Akademik.Mahasiswa;