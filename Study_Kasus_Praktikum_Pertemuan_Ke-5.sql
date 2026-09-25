-- =====================================================
-- STUDI KASUS LABORATORIUM - MANAJEMEN HAK AKSES LOGIN
-- =====================================================

-- Gunakan database utama
USE master;
GO

-- =====================================================
-- 0. (OPSIONAL) HAPUS JIKA SUDAH ADA (BIAR TIDAK ERROR)
-- =====================================================

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'admin_lab')
    DROP LOGIN admin_lab;
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'operator_lab')
    DROP LOGIN operator_lab;
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'teknisi_lab')
    DROP LOGIN teknisi_lab;
GO


-- =====================================================
-- 1. MEMBUAT LOGIN
-- =====================================================

CREATE LOGIN admin_lab
WITH PASSWORD = 'AdminLab123!';
GO

CREATE LOGIN operator_lab
WITH PASSWORD = 'OperatorLab123!';
GO

CREATE LOGIN teknisi_lab
WITH PASSWORD = 'TeknisiLab123!';
GO


-- =====================================================
-- 2. PEMBERIAN HAK AKSES SESUAI STUDI KASUS
-- =====================================================

-- admin_lab memiliki hak penuh
ALTER SERVER ROLE sysadmin
ADD MEMBER admin_lab;
GO

-- operator_lab hanya boleh membuat database
ALTER SERVER ROLE dbcreator
ADD MEMBER operator_lab;
GO

-- teknisi_lab hanya boleh mengelola login
ALTER SERVER ROLE securityadmin
ADD MEMBER teknisi_lab;
GO


-- =====================================================
-- 3. UJI COBA (VERIFIKASI HAK AKSES)
-- =====================================================

-- Cek role masing-masing login
SELECT 
    sp.name AS LoginName,
    sp.type_desc,
    slr.name AS ServerRole
FROM sys.server_role_members srm
JOIN sys.server_principals sp 
    ON srm.member_principal_id = sp.principal_id
JOIN sys.server_principals slr 
    ON srm.role_principal_id = slr.principal_id;
GO


-- =====================================================
-- 4. SIMULASI (OPSIONAL - UNTUK PEMBUKTIAN)
-- =====================================================

-- Simulasi operator membuat database (HARUS BISA)
EXECUTE AS LOGIN = 'operator_lab';
CREATE DATABASE TestOperatorDB;
REVERT;
GO

-- Simulasi teknisi membuat login (HARUS BISA)
EXECUTE AS LOGIN = 'teknisi_lab';
CREATE LOGIN user_uji WITH PASSWORD = 'User12345!';
REVERT;
GO

-- Simulasi admin (HARUS BISA SEMUA)
EXECUTE AS LOGIN = 'admin_lab';
CREATE DATABASE TestAdminDB;
REVERT;
GO