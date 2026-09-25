
-- SOAL 1: Perancangan Database Monitoring TA 
USE master;
GO

CREATE DATABASE D_Monitoring_TA
ON PRIMARY (
    -- File Utama (.mdf)
    NAME = 'MonitoringTA_Primary',
    FILENAME = 'D:\SQLData\MonitoringTA_Primary.mdf', 
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
),
FILEGROUP FG_Monitoring_TA (
    -- File Sekunder (.ndf)
    NAME = 'MonitoringTA_Secondary',
    FILENAME = 'D:\SQLData\MonitoringTA_Secondary.ndf', 
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
)
LOG ON (
    -- Log File (.ldf)
    NAME = 'MonitoringTA_Log',
    FILENAME = 'D:\SQLData\MonitoringTA_Log.ldf', 
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
);
GO



-- Verifikasi
SELECT name AS DatabaseName, state_desc 
FROM sys.databases 
WHERE name = 'D_Monitoring_TA';
GO



-- SOAL 2: CREATE, ALTER, DROP 
USE D_Monitoring_TA;
GO

-- Membuat Schema
CREATE SCHEMA akademik;   
GO
CREATE SCHEMA aktivitas;  
GO
CREATE SCHEMA arsip;      
GO

-- Membuat Tabel
-- 1. TABEL MAHASISWA
CREATE TABLE akademik.Mahasiswa (
    Nim CHAR(11) PRIMARY KEY,
    Nama VARCHAR(50) NOT NULL,
    Jurusan VARCHAR(30),
    Angkatan INT
);

-- 2. TABEL DOSEN 
CREATE TABLE akademik.Dosen (
    NIDN CHAR(10) PRIMARY KEY,
    Nama VARCHAR(50) NOT NULL,
    Prodi VARCHAR(30),
    Email VARCHAR(30),
    CONSTRAINT UQ_Email_Dosen UNIQUE (Email) 
);

-- 3. TABEL LOG BIMBINGAN
CREATE TABLE akademik.Log_Bimbingan (
    ID_Log INT IDENTITY(1,1) PRIMARY KEY, 
    Nim CHAR(11) NOT NULL, 
    NIDN CHAR(10) NOT NULL, 
    Tanggal DATE,
    Materi TEXT,
    Status VARCHAR(20),
    CONSTRAINT FK_Log_Mhs FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim),
    CONSTRAINT FK_Log_Dosen FOREIGN KEY (NIDN) REFERENCES akademik.Dosen(NIDN)
);

-- 4. TABEL PENGAJUAN PENDADARAN
CREATE TABLE akademik.Pengajuan_Pendadaran (
    ID_Pengajuan INT IDENTITY(1,1) PRIMARY KEY,
    ID_TA INT NOT NULL, 
    NIDN_Penguji1 CHAR(10) NOT NULL,
    NIDN_Penguji2 CHAR(10) NOT NULL,
    IPK DECIMAL(3,2) NOT NULL,
    SKS_Lulus INT NOT NULL,
    Tanggal_Pengajuan DATE NOT NULL DEFAULT GETDATE(),
    Tanggal_Ujian DATE,
    Ruangan VARCHAR(30),
    Status VARCHAR(20) NOT NULL DEFAULT 'Menunggu',
    Nilai CHAR(2),
    Catatan VARCHAR(500),
    -- Relasi
    CONSTRAINT FK_Pendadaran_TA
        FOREIGN KEY (ID_TA) REFERENCES aktivitas.Monitoring_TA(ID_TA),
    CONSTRAINT FK_Pendadaran_Penguji1
        FOREIGN KEY (NIDN_Penguji1) REFERENCES akademik.Dosen(NIDN),
    CONSTRAINT FK_Pendadaran_Penguji2
        FOREIGN KEY (NIDN_Penguji2) REFERENCES akademik.Dosen(NIDN),
    -- Validasi
    CONSTRAINT CHK_Status_Pendadaran
        CHECK (Status IN ('Menunggu', 'Disetujui', 'Ditolak', 'Selesai')),
    CONSTRAINT CHK_IPK
        CHECK (IPK BETWEEN 0.00 AND 4.00), -- Menggunakan BETWEEN lebih simpel
    CONSTRAINT CHK_SKS
        CHECK (SKS_Lulus >= 0)
);

-- 5. TABEL ARSIP
CREATE TABLE arsip.Arsip_TA (
    ID_Arsip INT IDENTITY(1,1) PRIMARY KEY,
    ID_TA INT,
    Tanggal_Arsip DATE DEFAULT GETDATE(), 
    CONSTRAINT FK_Arsip_TA FOREIGN KEY (ID_TA) REFERENCES aktivitas.Monitoring_TA(ID_TA)
);

-- 6. TABEL MONITORING_TA
CREATE TABLE aktivitas.Monitoring_TA (
    ID_TA INT IDENTITY(1,1) PRIMARY KEY,
    Nim CHAR(11) NOT NULL,
    NIDN_Pembimbing CHAR(10) NOT NULL,
    Judul_TA VARCHAR(255) NOT NULL,
    Status_TA VARCHAR(20) DEFAULT 'Aktif',
    CONSTRAINT FK_Monitoring_Mhs FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim),
    CONSTRAINT FK_Monitoring_Dosen FOREIGN KEY (NIDN_Pembimbing) REFERENCES akademik.Dosen(NIDN),
    CONSTRAINT CHK_Status CHECK (Status_TA IN ('Aktif', 'Lulus', 'Berhenti')) 
) ON FG_Monitoring_TA;

-- 7. TABEL STAFF TU
CREATE TABLE akademik.Staff_TU (
    ID_Staff INT IDENTITY(1,1) PRIMARY KEY,
    NIP VARCHAR(50) NOT NULL,
    Jabatan VARCHAR(30),
    Email VARCHAR(50),
    CONSTRAINT UQ_NIP_Staff   UNIQUE (NIP),
    CONSTRAINT UQ_Email_Staff UNIQUE (Email),
    CONSTRAINT CHK_Jabatan_Staff 
        CHECK (Jabatan IN ('Kepala TU', 'Staff Administrasi', 'Staff Keuangan', 'Staff Akademik')),
);

-- Menabahkan Data
USE D_Monitoring_TA;
GO

-- 1. Tambah Data Mahasiswa 
INSERT INTO akademik.Mahasiswa (Nim, Nama, Jurusan, Angkatan)
VALUES ('20250140157', 'Ahmad Rassya Maulana', 'Teknologi Informasi', 2025),
       ('20250140175', 'Muhammad Raffi imdad Robbani', 'Teknologi Informasi', 2025);

-- 2. Tambah Data Dosen 
INSERT INTO akademik.Dosen (NIDN, Nama, Prodi, Email)
VALUES ('0518048401', 'Apriliya Kurnianti, S.T., M.Eng.', 'Teknologi Informasi', 'aprilia@ft.umy.ac.id'),
       ('0707108402', 'Chayadi Oktomy N S, S.T., M.Eng., P.hD.', 'Teknologi Informasi', 'cahyadions@ft.umy.ac.id');

-- 3. Tambah Data Monitoring TA 
INSERT INTO aktivitas.Monitoring_TA (Nim, NIDN_Pembimbing, Judul_TA)
VALUES ('20250140157', '0518048401', 'Pengembangan AI untuk Deteksi Hama');

-- 4. Tambah Data Log Bimbingan 
INSERT INTO akademik.Log_Bimbingan (Nim, NIDN, Tanggal, Materi, Status)
VALUES ('20250140157', '0518048401', GETDATE(), 'Pembahasan Bab 1 Latar Belakang', 'Revisi');

-- 5. Tambah Data Pengajuan Pendadaran
INSERT INTO akademik.Pengajuan_Pendadaran (ID_TA, NIDN_Penguji1, NIDN_Penguji2, IPK, SKS_Lulus, Tanggal_Pengajuan, Tanggal_Ujian, Ruangan, Status, Nilai, Catatan)
VALUES (1, '0707108402', '0518048401', 3.75, 144, GETDATE(), '2026-06-01', 'Ruang Sidang A', 'Menunggu', NULL, 'Semua persyaratan telah terpenuhi'),
       (1, '0518048401', '0707108402', 3.80, 148, GETDATE(), '2026-06-05', 'Ruang Sidang B', 'Menunggu', NULL, 'Menunggu verifikasi berkas');
  
-- 6. INSERT DATA STAFF TU
INSERT INTO akademik.Staff_TU (NIP, Jabatan, Email) 
VALUES ('1234567890', 'Kepala TU', 'budi@ft.umy.ac.id'),
       ('0987654321', 'Staff Administrasi', 'siti@ft.umy.ac.id');

-- 2. Langsung cek
SELECT * FROM akademik.Staff_TU;

-- VERIFIKASI Cek data yang sudah masuk (Uji Relasi)
SELECT m.Nama, ta.Judul_TA, ta.Status_TA
FROM aktivitas.Monitoring_TA ta
JOIN akademik.Mahasiswa m ON ta.Nim = m.Nim;
GO       

-- Melihat Data Seluruh Tabel
-- Melihat semua data Mahasiswa
SELECT * FROM akademik.Mahasiswa;

-- Melihat semua data Monitoring TA
SELECT * FROM aktivitas.Monitoring_TA;

-- Melihat semua data Log Bimbingan
SELECT * FROM akademik.Log_Bimbingan;

-- Melihat semua data Log Bimbingan
SELECT * FROM akademik.Pengajuan_Pendadaran;

-- Melihat semua data Staff TU
SELECT * FROM akademik.Staff_TU;

-- ALTER TABLE: Menambahkan 2 kolom baru
ALTER TABLE akademik.Mahasiswa
ADD No_HP VARCHAR(13),
    Alamat VARCHAR(255);
GO

-- DROP Kolom: Menghapus satu kolom alamat dari tabel Mahasiswa
ALTER TABLE akademik.Mahasiswa
DROP COLUMN Alamat
GO

-- DROP Tabel: Menghapus satu tabel yang tidak diperlukan (arsip)
DROP TABLE arsip.Arsip_TA;
GO

-- VERIFIKASI Pastikan schema arsip sudah hilang
SELECT name FROM sys.schemas WHERE name = 'arsip';
GO


-- SOAL 3: Analisis Pemilihan Tipe Data (Di Exel)



-- Soal 4: Optimasi Storage dan I/O (Di Exel)



-- Soal 5 – Constraint dan Relasi 



-- Soal 6 – Referential Integrity 
-- 1. ON DELETE CASCADE
ALTER TABLE aktivitas.Monitoring_TA
ADD CONSTRAINT FK_Monitoring_Mhs_Cascade 
FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim)
ON DELETE CASCADE;

-- 2. ON DELETE SET NULL
ALTER TABLE aktivitas.Monitoring_TA
ADD CONSTRAINT FK_Monitoring_Mhs_SetNull 
FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim)
ON DELETE SET NULL;

-- 3. ON DELETE NO ACTION 
ALTER TABLE aktivitas.Monitoring_TA
ADD CONSTRAINT FK_Monitoring_Mhs_NoAction 
FOREIGN KEY (Nim) REFERENCES akademik.Mahasiswa(Nim)
ON DELETE NO ACTION;



-- Soal 7 – Login dan Authentication 
-- 1. Login dengan Windows Authentication Tidak Dibutuhkan Lagi Karena Sudah Ada sebelumnya
USE master;
GO

CREATE LOGIN [rassya\legion] FROM WINDOWS;
GO

-- 2. Login dengan SQL Server Authentication
CREATE LOGIN LoginDosen WITH PASSWORD = 'Dosen123!';
GO

-- Membuat login untuk Staf Akademik (SQL Server Authentication)
CREATE LOGIN LoginStaf WITH PASSWORD = 'PasswordStaf123!';
GO

-- Membuat login untuk Operator (SQL Server Authentication)
CREATE LOGIN LoginOperator WITH PASSWORD = 'PasswordOperator123!';
GO

-- Membuat login untuk Auditor (SQL Server Authentication)
CREATE LOGIN LoginAuditor WITH PASSWORD = 'PasswordAuditor123!';
GO

-- Kebijakan Password
ALTER LOGIN LoginDosen WITH 
    CHECK_POLICY = ON,          -- Memaksa aturan password kompleks (min 8 char, simbol, angka)
    CHECK_EXPIRATION = ON;      -- Memaksa user ganti password secara berkala

-- Default Database
ALTER LOGIN LoginDosen
WITH DEFAULT_DATABASE = D_Monitoring_TA;

-- Status Login
-- Menonaktifkan login
ALTER LOGIN LoginDosen DISABLE;

-- Mengaktifkan kembali login
ALTER LOGIN LoginDosen ENABLE;



-- Soal 8 – Fixed Server Roles 
-- 1. Memberikan akses Admin
ALTER SERVER ROLE sysadmin ADD MEMBER [rassya\legion];

-- 2. Memberikan akses Auditor
ALTER SERVER ROLE setupadmin ADD MEMBER AuditorUser;

-- 3. Memberikan akses Developer
ALTER SERVER ROLE dbcreator ADD MEMBER DevUser;



-- Soal 9 – User Database dan Mapping 
USE D_Monitoring_TA;
GO

-- Membuat User Database dari Login yang sudah ada
CREATE USER User_Staf_Akademik FOR LOGIN LoginStaf;
CREATE USER User_Operator_TA FOR LOGIN LoginOperator;
CREATE USER User_Auditor_Internal FOR LOGIN LoginAuditor;
GO

-- Memberikan hak akses spesifik ke tiap User (Mapping)
-- Staf Akademik: Full control di schema akademik
GRANT CONTROL ON SCHEMA::akademik TO User_Staf_Akademik;
GO

-- Operator: CRUD di schema aktivitas
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::aktivitas TO User_Operator_TA;
GO

-- Auditor: Read-only untuk seluruh database
GRANT SELECT ON SCHEMA::akademik TO User_Auditor_Internal;
GRANT SELECT ON SCHEMA::aktivitas TO User_Auditor_Internal;
GRANT SELECT ON SCHEMA::arsip TO User_Auditor_Internal;
GO

-- Membuat Role
CREATE ROLE Role_Akademik_Manager;
CREATE ROLE Role_TA_Operator;
CREATE ROLE Role_Sistem_Auditor;
GO

-- Memberikan Hak Akses (Izin) ke Role
-- Role_Akademik_Manager: Akses penuh pada schema akademik
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::akademik TO Role_Akademik_Manager;
GO

-- Role_TA_Operator: Akses penuh pada schema aktivitas (proses TA)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::aktivitas TO Role_TA_Operator;
GO

-- Role_Sistem_Auditor: Akses baca saja (Read-Only) pada seluruh database
GRANT SELECT ON SCHEMA::akademik TO Role_Sistem_Auditor;
GRANT SELECT ON SCHEMA::aktivitas TO Role_Sistem_Auditor;
GRANT SELECT ON SCHEMA::arsip TO Role_Sistem_Auditor;
GO

-- Memasukkan User ke dalam Role yang sesuai
ALTER ROLE Role_Akademik_Manager ADD MEMBER User_Staf_Akademik;
ALTER ROLE Role_TA_Operator ADD MEMBER User_Operator_TA;
ALTER ROLE Role_Sistem_Auditor ADD MEMBER User_Auditor_Internal;
GO

-- Menentukan Default Schema
-- Mengatur Default Schema untuk setiap User
ALTER USER User_Staf_Akademik WITH DEFAULT_SCHEMA = akademik;
ALTER USER User_Operator_TA WITH DEFAULT_SCHEMA = aktivitas;
ALTER USER User_Auditor_Internal WITH DEFAULT_SCHEMA = akademik; 
GO

-- VERIFIKASI Cek User Mapping di Database
SELECT dp.name AS UserName, dr.name AS RoleName
FROM sys.database_role_members drm
    JOIN sys.database_principals dp 
        ON drm.member_principal_id = dp.principal_id
    JOIN sys.database_principals dr 
        ON drm.role_principal_id = dr.principal_id;
GO

-- Soal 10 – Grant, Deny, Revoke
-- 1. Pelaksanaan GRANT (Memberikan Izin)
-- Operator: Diberikan izin untuk menambah dan mengubah log bimbingan
GRANT INSERT, UPDATE ON SCHEMA::aktivitas TO Role_TA_Operator;
GO

-- Auditor: Diberikan izin untuk membaca data master mahasiswa dan dosen
GRANT SELECT ON SCHEMA::akademik TO Role_Sistem_Auditor;
GO

-- Staf Akademik: Diberikan izin penuh untuk mengelola master data
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::akademik TO Role_Akademik_Manager;
GO

-- 2. Pelaksanaan DENY (Menolak Izin Secara Mutlak)
-- Auditor: Auditor TIDAK BISA mengubah data apa pun (mencegah manipulasi)
DENY DELETE, INSERT, UPDATE ON SCHEMA::akademik TO Role_Sistem_Auditor;
GO

-- 3. Pelaksanaan REVOKE (Mencabut Izin)
REVOKE SELECT ON SCHEMA::arsip FROM Role_TA_Operator;
GO

REVOKE DELETE ON SCHEMA::aktivitas TO Role_TA_Operator;
GO

-- VERIFIKASI Cek daftar izin (Permissions) yang aktif
SELECT 
    class_desc, 
    permission_name, 
    state_desc, 
    pr.name AS grantee_name
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('Role_TA_Operator', 'Role_Sistem_Auditor');
GO