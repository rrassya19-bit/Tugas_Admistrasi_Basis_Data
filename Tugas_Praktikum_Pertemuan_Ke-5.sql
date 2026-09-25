-- 1. Membuat login baru bernama dosen_lab
CREATE LOGIN dosen_lab
WITH PASSWORD = 'Password123!';

GO

-- 2. Memberikan role dbcreator kepada dosen_lab
ALTER SERVER ROLE dbcreator
ADD MEMBER dosen_lab;

GO

-- 3. Mengubah password dosen_lab
ALTER LOGIN dosen_lab
WITH PASSWORD = 'PasswordBaru123!';

GO

-- 4. Menampilkan seluruh role yang dimiliki dosen_lab
SELECT 
    sp.name AS LoginName,
    sr.name AS ServerRole
FROM sys.server_role_members srm
JOIN sys.server_principals sp 
    ON srm.member_principal_id = sp.principal_id
JOIN sys.server_principals sr 
    ON srm.role_principal_id = sr.principal_id
WHERE sp.name = 'dosen_lab';

GO

-- 5. Menonaktifkan login dosen_lab
ALTER LOGIN dosen_lab DISABLE;

GO

-- 6. Mengaktifkan kembali login dosen_lab
ALTER LOGIN dosen_lab ENABLE;

GO

-- 7. Menghapus role dbcreator dari dosen_lab
ALTER SERVER ROLE dbcreator
DROP MEMBER dosen_lab;

GO

-- 8. Menghapus login dosen_lab
DROP LOGIN dosen_lab;

GO