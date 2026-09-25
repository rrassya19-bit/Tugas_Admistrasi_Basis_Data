
-- 1. BUAT LOGIN BARU
CREATE LOGIN operator_krs 
WITH PASSWORD = 'Operator123!';



-- 2. MASUK KE DATABASE & BUAT USER
USE KampusPraktikum

CREATE USER operator_krs 
FOR LOGIN operator_krs;



-- 3. BUAT ROLE
CREATE ROLE role_operator_krs;



-- 4. HAK AKSES KE TABEL KRS (SELECT, INSERT, UPDATE)
GRANT SELECT, INSERT, UPDATE
ON akademik.KRS
TO role_operator_krs;



-- 5. HAK AKSES SELECT KE MAHASISWA & MATAKULIAH
GRANT SELECT
ON akademik.Mahasiswa
TO role_operator_krs;

GRANT SELECT
ON akademik.MataKuliah
TO role_operator_krs;



-- 6. TOLAK DELETE PADA KRS
DENY DELETE
ON akademik.KRS
TO role_operator_krs;



-- 7. TAMBAHKAN USER KE ROLE
ALTER ROLE role_operator_krs
ADD MEMBER operator_krs;



-- 8. UJI AKSES DENGAN EXECUTE AS USER
EXECUTE AS USER = 'operator_krs';

-- BERHASIL
SELECT * FROM akademik.KRS;

-- BERHASIL
INSERT INTO akademik.KRS (NIM, KodeMK, Semester)
VALUES ('20250140157', 'TI101', 2);

-- GAGAL (karena DENY DELETE)
DELETE FROM akademik.KRS WHERE ID_KRS = 999;

REVERT;



-- 9. TAMPILKAN PERMISSION USER
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');

SELECT * FROM fn_my_permissions('akademik.KRS', 'OBJECT');

SELECT * FROM fn_my_permissions('akademik.Mahasiswa', 'OBJECT');

SELECT * FROM fn_my_permissions('akademik.MataKuliah', 'OBJECT');

REVERT;
GO