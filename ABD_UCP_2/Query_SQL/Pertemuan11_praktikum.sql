
-- 1 - IDENTIFIKASI INDEX EXISTING 
--Langkah 1 – Gunakan Database
USE KampusPraktikum;

--Langkah 2 – Cek Struktur Index 
SELECT
    i.name AS NamaIndex,
    i.type_desc,
    i.is_primary_key
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('akademik.Mahasiswa');



-- 2 – Cek Fragmentasi Awal
SELECT
    OBJECT_NAME(object_id) AS NamaTabel,
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);



-- 3 – MEMBUAT FRAGMENTASI (5–30%) 
--Langkah 1 – Backup Data Awal
SELECT * INTO akademik.Mahasiswa_backup
FROM akademik.Mahasiswa;

--Langkah 2 – Insert Data Acak
--MAHASISWA
DECLARE @i INT = 1;

WHILE @i <= 3000
BEGIN
    INSERT INTO akademik.Mahasiswa (NIM, Nama, Alamat, NoHP, TanggalLahir, Email)
    VALUES (
        RIGHT('00000000000' + CAST(ABS(CHECKSUM(NEWID())) % 99999999999 AS VARCHAR), 11),
        'RandomNama' + CAST(@i AS VARCHAR),
        'Alamat' + CAST(@i AS VARCHAR),
        '08' + CAST(ABS(CHECKSUM(NEWID())) % 1000000000 AS VARCHAR),
        GETDATE(),
        'random' + CAST(@i AS VARCHAR) + '@email.com'
    );
    SET @i = @i + 1;
END


--Langkah 3 – Cek Fragmentasi Lagi
SELECT
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);



-- 4 – REORGANIZE (Untuk 5–30% atau lebih)4 
ALTER INDEX ALL ON akademik.Mahasiswa
REORGANIZE;

--Cek kembali fragmentasi → harus turun. 
SELECT
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);



-- 5 – REBUILD
ALTER INDEX ALL ON akademik.Mahasiswa
REBUILD;

--Cek kembali fragmentasi → turun mendekati 0%. 
SELECT
    avg_fragmentation_in_percent,
    page_count
FROM sys.dm_db_index_physical_stats
(DB_ID(), OBJECT_ID('akademik.Mahasiswa'), NULL, NULL, NULL);



-- 6 – UPDATE STATISTICS 
--Cari Nama Index / Statistik 
SELECT name
FROM sys.stats
WHERE object_id = OBJECT_ID('akademik.Mahasiswa');


--Gunakan Nama Tersebut (DBCC SHOW_STATISTICS)
DBCC SHOW_STATISTICS ('akademik.Mahasiswa', 'PK__Mahasisw__C7DEC338D3C83D33');

--Update Statistik
UPDATE STATISTICS akademik.Mahasiswa;

--Atau seluruh database
EXEC sp_updatestats;



-- 7 – DBCC CHECKDB
DBCC CHECKDB ('KampusPraktikum') WITH NO_INFOMSGS;