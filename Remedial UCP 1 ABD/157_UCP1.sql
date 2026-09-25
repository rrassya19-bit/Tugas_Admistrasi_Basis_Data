-- ======================================================
-- STUDI KASUS, SKENARIO DAN PENJELASAN SEMUA ADA DI WORD
-- ======================================================

-- ================================================================
--              BAGIAN A – DDL & ARSITEKTUR DATABASE
-- ================================================================

-- ===========================================
-- SOAL 1: Perancangan Database Monitoring TA 
-- ===========================================
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



-- ===========================================
-- SOAL 2: CREATE, ALTER, DROP 
-- ===========================================
USE D_Monitoring_TA;
GO

-- Membuat Schema
CREATE SCHEMA master;
GO

CREATE SCHEMA akademik;
GO

CREATE SCHEMA aktivitas;
GO

CREATE SCHEMA arsip;
GO

-- Membuat Tabel Induk
-- 1. TABEL MAHASISWA
CREATE TABLE master.Mahasiswa (
    Nim      CHAR(11)    NOT NULL,
    Nama     VARCHAR(50) NOT NULL,
    Jurusan  VARCHAR(30) NULL,
    Angkatan INT         NULL,
    CONSTRAINT PK_Mahasiswa PRIMARY KEY (Nim)
);
GO

-- 2. TABEL DOSEN 
CREATE TABLE master.Dosen (
    NIDN  CHAR(10)    NOT NULL,
    Nama  VARCHAR(50) NOT NULL,
    Prodi VARCHAR(30) NULL,
    Email VARCHAR(30) NULL,
    CONSTRAINT PK_Dosen       PRIMARY KEY (NIDN),
    CONSTRAINT UQ_Email_Dosen UNIQUE      (Email)
);
GO

-- 3. TABEL STAFF TU
CREATE TABLE master.Staff_TU (
    ID_Staff INT         NOT NULL IDENTITY(1,1),
    NIP      CHAR(20) NOT NULL,
    Jabatan  VARCHAR(30) NULL,
    Email    VARCHAR(30) NULL,
    CONSTRAINT PK_Staff_TU       PRIMARY KEY (ID_Staff),
    CONSTRAINT UQ_NIP_Staff      UNIQUE (NIP),
    CONSTRAINT UQ_Email_Staff    UNIQUE (Email),
    CONSTRAINT CHK_Jabatan_Staff CHECK (
        Jabatan IN ('Kepala TU', 'Staff Administrasi', 'Staff Keuangan', 'Staff Akademik')
    )
);
GO

-- Membuat Tabel Anak
-- 4. TABEL MONITORING_TA
CREATE TABLE akademik.Monitoring_TA (
    ID_TA           INT          IDENTITY(1,1) PRIMARY KEY,
    Nim             CHAR(11)     NOT NULL,
    NIDN_Pembimbing CHAR(10)     NOT NULL,
    Judul_TA        VARCHAR(255) NOT NULL,
    Status_TA       VARCHAR(20)  DEFAULT 'Aktif',
    CONSTRAINT FK_Monitoring_Dosen FOREIGN KEY (NIDN_Pembimbing) REFERENCES master.Dosen     (NIDN),
    CONSTRAINT CHK_Status_TA       CHECK (Status_TA IN ('Aktif', 'Lulus', 'Berhenti'))
);

-- 5. TABEL PENGAJUAN PENDADARAN
CREATE TABLE akademik.Pengajuan_Pendadaran (
    ID_Pengajuan      INT          NOT NULL IDENTITY(1,1),
    ID_TA             INT          NOT NULL,
    NIDN_Penguji1     CHAR(10)     NOT NULL,
    NIDN_Penguji2     CHAR(10)     NOT NULL,
    IPK               DECIMAL(3,2) NOT NULL,
    SKS_Lulus         INT          NOT NULL,
    Tanggal_Pengajuan DATE         NOT NULL DEFAULT GETDATE(),
    Tanggal_Ujian     DATE         NULL,
    Ruangan           VARCHAR(30)  NULL,
    Status            VARCHAR(20)  NOT NULL DEFAULT 'Menunggu',
    Nilai             CHAR(2)      NULL,
    Catatan           VARCHAR(255) NULL,
    CONSTRAINT PK_Pengajuan_Pendadaran PRIMARY KEY (ID_Pengajuan),
    CONSTRAINT FK_Pendadaran_TA
        FOREIGN KEY (ID_TA)         REFERENCES akademik.Monitoring_TA (ID_TA),
    CONSTRAINT FK_Pendadaran_Penguji1
        FOREIGN KEY (NIDN_Penguji1) REFERENCES master.Dosen (NIDN),
    CONSTRAINT FK_Pendadaran_Penguji2
        FOREIGN KEY (NIDN_Penguji2) REFERENCES master.Dosen (NIDN),
    CONSTRAINT CHK_Status_Pendadaran
        CHECK (Status IN ('Menunggu', 'Disetujui', 'Ditolak', 'Selesai')),
    CONSTRAINT CHK_IPK
        CHECK (IPK BETWEEN 0.00 AND 4.00),
    CONSTRAINT CHK_SKS
        CHECK (SKS_Lulus >= 0),
    CONSTRAINT CHK_Penguji_Beda
        CHECK (NIDN_Penguji1 <> NIDN_Penguji2),
    CONSTRAINT CHK_Nilai
        CHECK (Nilai IN ('A', 'AB', 'B', 'BC', 'C', 'D', 'E') OR Nilai IS NULL)
);
GO

-- 6. TABEL LOG BIMBINGAN
CREATE TABLE aktivitas.Log_Bimbingan (
    ID_Log  INT           NOT NULL IDENTITY(1,1),
    Nim     CHAR(11)      NOT NULL,
    NIDN    CHAR(10)      NOT NULL,
    Tanggal DATE          NULL,
    Materi  VARCHAR(255) NULL,
    Status  VARCHAR(20)   NULL,
    CONSTRAINT PK_Log_Bimbingan PRIMARY KEY (ID_Log),
    CONSTRAINT FK_Log_Dosen     FOREIGN KEY (NIDN) REFERENCES master.Dosen     (NIDN),
    CONSTRAINT CHK_Status_Log   CHECK (Status IN ('Disetujui', 'Revisi', 'Menunggu') OR Status IS NULL)
);
GO

-- 7. TABEL ARSIP
CREATE TABLE arsip.Arsip_TA (
    ID_Arsip      INT  NOT NULL IDENTITY(1,1),
    ID_TA         INT  NULL,
    Tanggal_Arsip DATE NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Arsip_TA PRIMARY KEY (ID_Arsip),
    CONSTRAINT FK_Arsip_TA FOREIGN KEY (ID_TA) REFERENCES akademik.Monitoring_TA (ID_TA)
);
GO

-- Menabahkan Data
USE D_Monitoring_TA;
GO

-- 1. Tambah Data Mahasiswa 
INSERT INTO master.Mahasiswa (Nim, Nama, Jurusan, Angkatan)
VALUES ('20250140157', 'Ahmad Rassya Maulana', 'Teknologi Informasi', 2025),
       ('20250140175', 'Muhammad Raffi Imdad Robbani', 'Teknologi Informasi', 2025);
GO

-- 2. Tambah Data Dosen 
INSERT INTO master.Dosen (NIDN, Nama, Prodi, Email)
VALUES ('0518048401', 'Apriliya Kurnianti, S.T., M.Eng.', 'Teknologi Informasi', 'aprilia@ft.umy.ac.id'),
       ('0707108402', 'Chayadi Oktomy N S, S.T., M.Eng., P.hD.', 'Teknologi Informasi', 'cahyadions@ft.umy.ac.id');
GO

-- 3. Tambah Data Staff TU
INSERT INTO master.Staff_TU (NIP, Jabatan, Email)
VALUES ('1234567890', 'Kepala TU', 'budi@ft.umy.ac.id'),
       ('0987654321', 'Staff Administrasi', 'siti@ft.umy.ac.id');
GO

-- 4. Tambah Data Monitoring TA 
INSERT INTO akademik.Monitoring_TA (Nim, NIDN_Pembimbing, Judul_TA)
VALUES ('20250140157', '0518048401', 'Pengembangan AI untuk Deteksi Hama');
GO

-- 5. Tambah Data Log Bimbingan
INSERT INTO aktivitas.Log_Bimbingan (Nim, NIDN, Tanggal, Materi, Status)
VALUES ('20250140157', '0518048401', GETDATE(), 'Pembahasan Bab 1 Latar Belakang', 'Revisi');
GO

-- 6. Tambah Data Pengajuan Pendadaran
INSERT INTO akademik.Pengajuan_Pendadaran (ID_TA, NIDN_Penguji1, NIDN_Penguji2, IPK, SKS_Lulus, Tanggal_Pengajuan, Tanggal_Ujian, Ruangan, Status, Nilai, Catatan)
VALUES (1, '0707108402', '0518048401', 3.75, 144, GETDATE(), '2026-06-01', 'Ruang Sidang A', 'Menunggu', NULL, 'Semua persyaratan telah terpenuhi'),
       (1, '0518048401', '0707108402', 3.80, 148, GETDATE(), '2026-06-05', 'Ruang Sidang B', 'Menunggu', NULL, 'Menunggu verifikasi berkas');
GO

-- VERIFIKASI Cek semua tabel dan schema yang ada
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- VERIFIKASI Cek semua FK dan constraint sudah terdaftar
SELECT 
    CONSTRAINT_NAME,
    TABLE_SCHEMA,
    TABLE_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
ORDER BY TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_TYPE;
GO

-- VERIFIKASI Cek data yang sudah di-INSERT per tabel
SELECT * FROM master.Mahasiswa;
SELECT * FROM master.Dosen;
SELECT * FROM master.Staff_TU;
SELECT * FROM akademik.Monitoring_TA;
SELECT * FROM aktivitas.Log_Bimbingan;
SELECT * FROM akademik.Pengajuan_Pendadaran;
SELECT * FROM arsip.Arsip_TA;
GO

-- VERIVIKASI Cek relasi FK — (memastikan data menyambung antar tabel)
-- Monitoring TA 
SELECT 
    m.Nim,
    mhs.Nama        AS Nama_Mahasiswa,
    d.Nama          AS Nama_Pembimbing,
    m.Judul_TA,
    m.Status_TA
FROM akademik.Monitoring_TA m
JOIN master.Mahasiswa mhs ON m.Nim             = mhs.Nim
JOIN master.Dosen     d   ON m.NIDN_Pembimbing = d.NIDN;
GO

-- Log bimbingan lengkap dengan nama mahasiswa dan dosen
SELECT 
    lb.ID_Log,
    mhs.Nama  AS Nama_Mahasiswa,
    d.Nama    AS Nama_Dosen,
    lb.Tanggal,
    lb.Materi,
    lb.Status
FROM aktivitas.Log_Bimbingan lb
JOIN master.Mahasiswa mhs ON lb.Nim  = mhs.Nim
JOIN master.Dosen     d   ON lb.NIDN = d.NIDN;
GO

-- Pengajuan pendadaran lengkap dengan nama semua pihak
SELECT 
    pp.ID_Pengajuan,
    mhs.Nama  AS Nama_Mahasiswa,
    p1.Nama   AS Penguji_1,
    p2.Nama   AS Penguji_2,
    pp.IPK,
    pp.SKS_Lulus,
    pp.Tanggal_Ujian,
    pp.Status,
    pp.Nilai
FROM akademik.Pengajuan_Pendadaran pp
JOIN akademik.Monitoring_TA m  ON pp.ID_TA         = m.ID_TA
JOIN master.Mahasiswa       mhs ON m.Nim            = mhs.Nim
JOIN master.Dosen           p1  ON pp.NIDN_Penguji1 = p1.NIDN
JOIN master.Dosen           p2  ON pp.NIDN_Penguji2 = p2.NIDN;
GO

-- ALTER TABLE: Menambahkan 2 kolom baru di tabel mahasiswa
ALTER TABLE master.Mahasiswa
ADD No_HP VARCHAR(13),
    Alamat VARCHAR(255);
GO

-- VERIFIKASI ALTER TABLE — kolom baru berhasil ditambahkan
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'master'
  AND TABLE_NAME   = 'Mahasiswa'
ORDER BY ORDINAL_POSITION;
GO

-- DROP Kolom: Menghapus satu kolom dari tabel Mahasiswa
ALTER TABLE master.Mahasiswa
DROP COLUMN No_HP
GO

-- VERIFIKASI DROP COLUMN — kolom No_HP sudah hilang
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'master'
  AND TABLE_NAME   = 'Mahasiswa'
  AND COLUMN_NAME  = 'No_HP';
GO 

-- DROP Tabel: Menghapus satu tabel yang tidak diperlukan (arsip)
DROP TABLE arsip.Arsip_TA;
GO

-- VERIFIKASI DROP TABLE — tabel Arsip_TA sudah hilang
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'Arsip_TA';
GO




-- ================================================================
--           BAGIAN B – TIPE DATA & STRATEGI PENYIMPANAN 
-- ================================================================

-- ===========================================
-- SOAL 3: Analisis Pemilihan Tipe Data 
-- ===========================================
-- (Di Exel)


-- ===========================================
-- Soal 4: Optimasi Storage dan I/O 
-- ===========================================
-- (Di Word)




-- ================================================================
--            BAGIAN C – INTEGRITAS DATA & CONSTRAINTS 
-- ================================================================

-- ===========================================
-- Soal 5 – Constraint dan Relasi 
-- ===========================================
-- Sudah ada CONSTRAIN dan RELASI pada semua tabel diatas, yang mencangkup:
-- 1. Primary Key 
-- 2. Foreign Key 
-- 3. Check Constraint 
-- 4. Default Constraint 
-- 5. Unique Constraint 
-- 6. Not Null Constraint



-- ===========================================
-- Soal 6 – Referential Integrity 
-- ===========================================
-- 1. ON DELETE CASCADE
ALTER TABLE akademik.Monitoring_TA
ADD CONSTRAINT FK_Monitoring_Mhs_Cascade
FOREIGN KEY (Nim) REFERENCES master.Mahasiswa(Nim)
ON DELETE CASCADE;
GO

-- 2. ON DELETE SET NULL
ALTER TABLE aktivitas.Log_Bimbingan
ADD CONSTRAINT FK_Log_Mhs_SetNull
FOREIGN KEY (Nim) REFERENCES master.Mahasiswa(Nim)
ON DELETE SET NULL;
GO

-- 3. ON DELETE NO ACTION 
ALTER TABLE akademik.Pengajuan_Pendadaran
ADD CONSTRAINT FK_Pendadaran_TA_NoAction
FOREIGN KEY (ID_TA) REFERENCES akademik.Monitoring_TA(ID_TA)
ON DELETE NO ACTION;
GO




-- ================================================================
-- BAGIAN D – KEAMANAN 1: AUTENTIKASI & SERVER ROLES 
-- ================================================================

-- ===========================================
-- Soal 7 – Login dan Authentication 
-- ===========================================
USE master;
GO

-- 1. Login dengan Windows Authentication
-- Tidak Dibutuhkan Lagi Karena Sudah Ada sebelumnya
CREATE LOGIN [rassya\legion] FROM WINDOWS;
GO


-- 2. Login dengan SQL Server Authentication
-- Membuat login untuk Dosen (SQL Server Authentication)
CREATE LOGIN LoginDosen WITH PASSWORD = 'Dosen123!';
GO

-- Membuat login untuk Staf (SQL Server Authentication)
CREATE LOGIN LoginStaf WITH PASSWORD = 'PasswordStaf123!';
GO

-- Membuat login untuk Operator (SQL Server Authentication)
CREATE LOGIN LoginOperator WITH PASSWORD = 'PasswordOperator123!';
GO

-- Membuat login untuk Auditor (SQL Server Authentication)
CREATE LOGIN LoginAuditor WITH PASSWORD = 'PasswordAuditor123!';
GO


-- 3. Kebijakan Password (Password Policy)
-- LoginDosen: wajib kompleks + wajib ganti berkala
ALTER LOGIN LoginDosen
    WITH CHECK_POLICY    = ON,
         CHECK_EXPIRATION = ON;
GO

-- LoginStaf: sama seperti dosen
ALTER LOGIN LoginStaf
    WITH CHECK_POLICY    = ON,
         CHECK_EXPIRATION = ON;
GO

-- LoginOperator: kebijakan kompleks, tapi tidak perlu expired
ALTER LOGIN LoginOperator
    WITH CHECK_POLICY    = ON,
         CHECK_EXPIRATION = ON;
GO

-- LoginAuditor: kebijakan kompleks, expiration OFF (akun monitoring stabil)
ALTER LOGIN LoginAuditor
    WITH CHECK_POLICY    = ON,
         CHECK_EXPIRATION = OFF;
GO


-- 4. Defaul DataBase
ALTER LOGIN LoginDosen    WITH DEFAULT_DATABASE = D_Monitoring_TA;
GO

ALTER LOGIN LoginStaf     WITH DEFAULT_DATABASE = D_Monitoring_TA;
GO

ALTER LOGIN LoginOperator WITH DEFAULT_DATABASE = D_Monitoring_TA;
GO

ALTER LOGIN LoginAuditor  WITH DEFAULT_DATABASE = D_Monitoring_TA;
GO


-- 5. Status Login (Enable / Disable)
-- Nonaktifkan (contoh: dosen sedang cuti / akun perlu dibekukan)
ALTER LOGIN LoginDosen DISABLE;
GO

-- Aktifkan kembali
ALTER LOGIN LoginDosen ENABLE;
GO

-- Nonaktifkan semua saat maintenance
ALTER LOGIN LoginStaf     DISABLE;
ALTER LOGIN LoginOperator DISABLE;
ALTER LOGIN LoginAuditor  DISABLE;
GO

-- Aktifkan kembali setelah maintenance
ALTER LOGIN LoginStaf     ENABLE;
ALTER LOGIN LoginOperator ENABLE;
ALTER LOGIN LoginAuditor  ENABLE;
GO


-- VERIFIKASI
-- Cek semua login beserta status dan default database
SELECT 
    name          AS NamaLogin,
    type_desc     AS TipeLogin,
    is_disabled   AS Nonaktif,
    default_database_name AS DefaultDatabase
FROM sys.server_principals
WHERE name IN (
    'LoginDosen', 'LoginStaf', 
    'LoginOperator', 'LoginAuditor'
)
ORDER BY name;
GO

-- Cek kebijakan password
SELECT 
    name              AS NamaLogin,
    is_policy_checked AS CheckPolicy,
    is_expiration_checked AS CheckExpiration,
    is_disabled       AS Nonaktif
FROM sys.sql_logins
WHERE name IN (
    'LoginDosen', 'LoginStaf', 
    'LoginOperator', 'LoginAuditor'
)
ORDER BY name;
GO



-- ===========================================
-- Soal 8 – Fixed Server Roles
-- ===========================================
-- Login sudah dibuat di Soal 7:
-- LoginDosen, LoginStaf, LoginOperator, LoginAuditor

USE master;
GO

-- 1. ADMINISTRATOR → sysadmin
-- Role    : sysadmin
-- Alasan  : Administrator bertanggung jawab atas seluruh instance SQL Server, termasuk konfigurasi server, backup, restore, dan manajemen login. sysadmin memberikan akses penuh tanpa batasan.
-- Risiko  : Jika akun ini diretas atau disalahgunakan, pelaku dapat menghapus seluruh database, membuat login baru dengan hak istimewa, mengekspor data sensitif, atau mematikan server.
-- Contoh Penyalahgunaan: Admin nakal membuat login baru tersembunyi (backdoor login) dengan hak sysadmin, lalu menjual akses ke pihak luar.
-- ==============================================================================================================================================================================================
-- Untuk keperluan demonstrasi, buat login SQL khusus admin
CREATE LOGIN LoginAdmin WITH PASSWORD = 'Admin@Secure123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = ON;
GO

-- Memberikan fixed server role sysadmin ke Administrator
ALTER SERVER ROLE sysadmin ADD MEMBER LoginAdmin;
GO

-- Verifikasi
SELECT 
    SP.name         AS LoginName,
    SP.type_desc    AS LoginType,
    SRP.name        AS ServerRole
FROM sys.server_role_members SRM
JOIN sys.server_principals    SP  ON SRM.member_principal_id = SP.principal_id
JOIN sys.server_principals    SRP ON SRM.role_principal_id   = SRP.principal_id
WHERE SP.name = 'LoginAdmin';
GO

-- 2. OPERATOR → dbcreator + bulkadmin
-- Role    : dbcreator
-- Alasan  : Operator bertugas membuat dan mengelola struktur database (membuat database baru, melakukan restore untuk keperluan operasional). dbcreator mengizinkan CREATE, ALTER, DROP, dan RESTORE database tanpa memberikan kendali penuh atas server.
-- Role    : bulkadmin
-- Alasan  : Operator juga bertanggung jawab impor data massal (bulk insert) dari file eksternal, misalnya data mahasiswa baru dari sistem akademik.
-- Risiko  : Operator bisa membuat database liar yang tidak terdokumentasi, atau menyalahgunakan bulk insert untuk mengimpor data palsu / memanipulasi data mahasiswa dan nilai.
-- Contoh Penyalahgunaan: Operator membuat database bayangan (shadow DB) untuk menyimpan salinan data mahasiswa secara ilegal, lalu mengekspornya keluar.
-- =======================================================================================================================================================================================================================================================
ALTER SERVER ROLE dbcreator ADD MEMBER LoginOperator;
GO

ALTER SERVER ROLE bulkadmin ADD MEMBER LoginOperator;
GO

-- Verifikasi
SELECT 
    SP.name      AS LoginName,
    SRP.name     AS ServerRole
FROM sys.server_role_members SRM
JOIN sys.server_principals    SP  ON SRM.member_principal_id = SP.principal_id
JOIN sys.server_principals    SRP ON SRM.role_principal_id   = SRP.principal_id
WHERE SP.name = 'LoginOperator';
GO

-- 3. STAF INPUT DATA → Tidak diberikan Fixed Server Role
-- Role    : (Tidak ada — hanya Database-level role)
-- Alasan  : Staf input data hanya perlu mengakses satu database tertentu (D_Monitoring_TA). Fixed server role bekerja di level instance, sehingga tidak tepat dan terlalu luas untuk staf input. Hak akses staf akan diatur di Soal 9 dan 10 (database user + GRANT).
-- Risiko jika diberi Fixed Server Role (misal processadmin): Staf bisa membunuh (KILL) proses/sesi pengguna lain, menyebabkan gangguan operasional sistem secara sengaja.
-- Contoh Penyalahgunaan: Staf yang tidak puas mematikan sesi login dosen atau admin sehingga mereka tidak dapat mengakses sistem saat sidang berlangsung.
-- ==================================================================================================================================================================================================================================================================

-- (Tidak ada ALTER SERVER ROLE untuk LoginStaf — diatur di level database)

-- 4. AUDITOR → securityadmin (READ ONLY — dengan catatan)
-- Role    : securityadmin
-- Alasan  : Auditor perlu melihat dan memverifikasi konfigurasi login, kebijakan password, dan hak akses yang ada di server untuk keperluan audit keamanan dan kepatuhan. securityadmin mengizinkan manajemen login dan pembacaan konfigurasi keamanan server.
-- Risiko  : securityadmin dapat mereset password login lain (kecuali sysadmin), yang berarti auditor berpotensi mengambil alih akun pengguna lain.
-- Contoh Penyalahgunaan: Auditor mereset password LoginDosen, lalu login sebagai dosen untuk mengubah nilai mahasiswa tertentu tanpa terdeteksikarena aktivitas terekam atas nama dosen.
-- ===================================================================================================================================================================================================================================================================
ALTER SERVER ROLE securityadmin ADD MEMBER LoginAuditor;
GO

-- Verifikasi
SELECT 
    SP.name      AS LoginName,
    SRP.name     AS ServerRole
FROM sys.server_role_members SRM
JOIN sys.server_principals    SP  ON SRM.member_principal_id = SP.principal_id
JOIN sys.server_principals    SRP ON SRM.role_principal_id   = SRP.principal_id
WHERE SP.name = 'LoginAuditor';
GO

-- 5. DEVELOPER → setupadmin (terbatas)
-- Role    : setupadmin
-- Alasan  : Developer perlu mengelola linked server untuk keperluan pengembangan integrasi sistem (misal: koneksi ke sistem akademik atau sistem keuangan kampus). setupadmin hanya mengizinkan pengelolaan linked server dan startup procedures, tanpa akses ke data atau struktur database produksi.
-- Risiko  : Developer bisa menambahkan linked server ke server eksternal yang tidak terotorisasi, membuka jalur transfer data keluar.
-- Contoh Penyalahgunaan: Developer jahat mendaftarkan linked server ke server pribadinya, lalu menjalankan query untuk menyalin seluruh tabel mahasiswa dan data pendadaran ke server luar melalui jalur tersebut.
-- ===================================================================================================================================================================================================================================================================================================
-- Buat login Developer
CREATE LOGIN LoginDeveloper WITH PASSWORD = 'Dev@Secure456!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = ON;
GO

ALTER SERVER ROLE setupadmin ADD MEMBER LoginDeveloper;
GO

-- Verifikasi
SELECT 
    SP.name      AS LoginName,
    SRP.name     AS ServerRole
FROM sys.server_role_members SRM
JOIN sys.server_principals    SP  ON SRM.member_principal_id = SP.principal_id
JOIN sys.server_principals    SRP ON SRM.role_principal_id   = SRP.principal_id
WHERE SP.name = 'LoginDeveloper';
GO

-- VERIFIKASI AKHIR
SELECT 
    SP.name         AS LoginName,
    SP.type_desc    AS JenisLogin,
    SRP.name        AS FixedServerRole,
    SP.is_disabled  AS Dinonaktifkan
FROM sys.server_role_members SRM
JOIN sys.server_principals    SP  ON SRM.member_principal_id = SP.principal_id
JOIN sys.server_principals    SRP ON SRM.role_principal_id   = SRP.principal_id
WHERE SP.name IN ('LoginAdmin', 'LoginOperator', 'LoginAuditor', 'LoginDeveloper', 'LoginStaf')
ORDER BY SRP.name, SP.name;
GO




-- ================================================================
-- BAGIAN E – KEAMANAN 2: OTORISASI & USER MAPPING  
-- ================================================================

-- ===========================================
-- Soal 9 – User Database dan Mapping 
-- ===========================================
USE D_Monitoring_TA;
GO

-- MEMBUAT DATABASE ROLES
-- Role 1: role_dosen
-- Deskripsi : Digunakan oleh dosen pembimbing/penguji. Dapat melihat data TA, log bimbingan, dan pengajuan pendadaran, serta menginput/mengupdate log bimbingan miliknya.
CREATE ROLE role_dosen;
GO

-- Role 2: role_staf
-- Deskripsi : Digunakan oleh staf administrasi/TU. Dapat menginput dan mengupdate data mahasiswa, monitoring TA, serta pengajuan pendadaran. Tidak dapat menghapus data.
CREATE ROLE role_staf;
GO

-- Role 3: role_auditor
-- Deskripsi : Digunakan oleh auditor/pemeriksa sistem. Hanya dapat membaca (SELECT) semua tabel tanpa bisa mengubah, menambah, atau menghapus data apapun.
CREATE ROLE role_auditor;
GO

-- Verifikasi role berhasil dibuat
SELECT name AS NamaRole, type_desc AS JenisRole
FROM sys.database_principals
WHERE type = 'R'
  AND name IN ('role_dosen', 'role_staf', 'role_auditor');
GO


-- MEMBUAT DATABASE USER DAN MAPPING KE LOGIN
-- User 1: UserDosen
-- Mapping  : LoginDosen (dibuat di Soal 7)
-- Schema   : akademik (default schema dosen adalah skema akademik, sehingga query tanpa prefix schema langsung mengarah ke sana)
-- Alasan   : Dosen paling sering bekerja dengan tabel di schema akademik (Monitoring_TA, Pengajuan_Pendadaran) dan aktivitas (Log_Bimbingan)
CREATE USER UserDosen
    FOR LOGIN LoginDosen
    WITH DEFAULT_SCHEMA = akademik;
GO

-- User 2: UserStaf
-- Mapping  : LoginStaf karena staf sering mengelola data Mahasiswa, Dosen, Staff_TU)
-- Alasan   : Staf TU paling sering bekerja dengan tabel master untuk keperluan administrasi dan verifikasi data dasar
CREATE USER UserStaf
    FOR LOGIN LoginStaf
    WITH DEFAULT_SCHEMA = master;
GO

-- User 3: UserAuditor
-- Mapping  : LoginAuditor
-- Schema   : dbo (default schema auditor adalah dbo karena auditor perlu melihat lintas schema tanpa default tertentu)
CREATE USER UserAuditor
    FOR LOGIN LoginAuditor
    WITH DEFAULT_SCHEMA = dbo;
GO

-- Verifikasi user dan mapping berhasil
SELECT 
    dp.name         AS NamaUser,
    dp.type_desc    AS JenisUser,
    dp.default_schema_name AS DefaultSchema,
    sp.name         AS LoginYangDiMapping
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.name IN ('UserDosen', 'UserStaf', 'UserAuditor');
GO


-- MENEMPATKAN USER KE ROLE DATABASE
-- UserDosen → role_dosen
ALTER ROLE role_dosen ADD MEMBER UserDosen;
GO

-- UserStaf → role_staf
ALTER ROLE role_staf ADD MEMBER UserStaf;
GO

-- UserAuditor → role_auditor
ALTER ROLE role_auditor ADD MEMBER UserAuditor;
GO

-- Verifikasi keanggotaan role
SELECT 
    r.name  AS NamaRole,
    m.name  AS NamaUser
FROM sys.database_role_members drm
JOIN sys.database_principals   r ON drm.role_principal_id   = r.principal_id
JOIN sys.database_principals   m ON drm.member_principal_id = m.principal_id
WHERE r.name IN ('role_dosen', 'role_staf', 'role_auditor')
ORDER BY r.name, m.name;
GO


-- VERIFIKASI AKHIR 
-- Melihat semua user, login yang dimapping, default schema, dan role-nya
SELECT 
    u.name                  AS NamaUser,
    u.default_schema_name   AS DefaultSchema,
    l.name                  AS LoginYangDiMapping,
    r.name                  AS Role
FROM sys.database_principals u
LEFT JOIN sys.server_principals       l   ON u.sid = l.sid
LEFT JOIN sys.database_role_members   drm ON u.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals     r   ON drm.role_principal_id = r.principal_id
WHERE u.name IN ('UserDosen', 'UserStaf', 'UserAuditor')
ORDER BY u.name;
GO



-- ===========================================
-- Soal 10 – Grant, Deny, Revoke
-- ===========================================
USE master;
GO

-- Login untuk mahasiswa (mewakili akun mahasiswa yang bisa login ke sistem)
CREATE LOGIN LoginMahasiswa WITH PASSWORD = 'Mhs@Secure123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;
GO

USE D_Monitoring_TA;
GO

-- User database untuk mahasiswa
CREATE USER UserMahasiswa
    FOR LOGIN LoginMahasiswa
    WITH DEFAULT_SCHEMA = akademik;
GO

-- Role khusus mahasiswa (read-only, hanya data miliknya)
CREATE ROLE role_mahasiswa;
GO

ALTER ROLE role_mahasiswa ADD MEMBER UserMahasiswa;
GO


-- GRANT (Minimal 3 Izin)
-- GRANT 1: role_auditor → SELECT di semua schema
-- Auditor hanya boleh membaca seluruh data untuk keperluan audit
GRANT SELECT ON SCHEMA::master    TO role_auditor;
GRANT SELECT ON SCHEMA::akademik  TO role_auditor;
GRANT SELECT ON SCHEMA::aktivitas TO role_auditor;
GO

-- GRANT 2: role_staf → SELECT, INSERT, UPDATE di schema master & akademik
-- Staf TU perlu mengelola data mahasiswa, monitoring TA, dan pendadaran
GRANT SELECT, INSERT, UPDATE ON SCHEMA::master    TO role_staf;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::akademik  TO role_staf;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::aktivitas TO role_staf;
GO

-- GRANT 3: role_dosen → SELECT di akademik & aktivitas + INSERT, UPDATE pada Log_Bimbingan (log bimbingannya sendiri)
-- Dosen perlu melihat data TA dan menginput log bimbingan
GRANT SELECT ON SCHEMA::akademik  TO role_dosen;
GRANT SELECT ON SCHEMA::aktivitas TO role_dosen;
GRANT INSERT, UPDATE ON aktivitas.Log_Bimbingan TO role_dosen;
GO

-- GRANT 4: role_mahasiswa → SELECT pada tabel tertentu saja
-- Mahasiswa hanya boleh melihat data TA dan log bimbingan miliknya
-- (pembatasan WHERE Nim = user sendiri akan dikontrol lewat VIEW di bawah)
CREATE VIEW akademik.vw_TA_Mahasiswa AS
SELECT 
    m.ID_TA,
    mhs.Nim,
    mhs.Nama,
    m.Judul_TA,
    m.Status_TA,
    d.Nama AS Nama_Pembimbing
FROM akademik.Monitoring_TA m
JOIN master.Mahasiswa mhs ON m.Nim = mhs.Nim
JOIN master.Dosen d ON m.NIDN_Pembimbing = d.NIDN
WHERE m.Nim = (
    SELECT TOP 1 Nim FROM master.Mahasiswa WHERE Nim = '20250140157'
);
GO
-- Mahasiswa hanya melihat data miliknya berdasarkan mapping NIM ke login
-- Dalam implementasi nyata, NIM disimpan di tabel UserProfile
-- Untuk demo: hardcode NIM mahasiswa yang login

CREATE VIEW akademik.vw_Pendadaran_Mahasiswa AS
SELECT 
    pp.ID_Pengajuan,
    mhs.Nama AS Nama_Mahasiswa,
    pp.IPK,
    pp.SKS_Lulus,
    pp.Tanggal_Pengajuan,
    pp.Tanggal_Ujian,
    pp.Ruangan,
    pp.Status,
    pp.Nilai,
    pp.Catatan
FROM akademik.Pengajuan_Pendadaran pp
JOIN akademik.Monitoring_TA m ON pp.ID_TA = m.ID_TA
JOIN master.Mahasiswa mhs ON m.Nim = mhs.Nim
WHERE m.Nim = '20250140157';
GO

CREATE VIEW aktivitas.vw_LogBimbingan_Mahasiswa AS
SELECT 
    lb.ID_Log,
    mhs.Nama AS Nama_Mahasiswa,
    d.Nama AS Nama_Dosen,
    lb.Tanggal,
    lb.Materi,
    lb.Status
FROM aktivitas.Log_Bimbingan lb
JOIN master.Mahasiswa mhs ON lb.Nim = mhs.Nim
JOIN master.Dosen d ON lb.NIDN = d.NIDN
WHERE lb.Nim = '20250140157';
GO

-- Grant SELECT pada VIEW ke role_mahasiswa (bukan tabel langsung)
GRANT SELECT ON akademik.vw_TA_Mahasiswa           TO role_mahasiswa;
GRANT SELECT ON akademik.vw_Pendadaran_Mahasiswa    TO role_mahasiswa;
GRANT SELECT ON aktivitas.vw_LogBimbingan_Mahasiswa TO role_mahasiswa;
GO

-- GRANT 5: UserDosen (langsung) → EXECUTE stored procedure tertentu
-- grant langsung ke user, bukan role
-- Buat stored procedure untuk update status log bimbingan
CREATE PROCEDURE aktivitas.usp_UpdateStatusBimbingan
    @ID_Log  INT,
    @Status  VARCHAR(20)
AS
BEGIN
    UPDATE aktivitas.Log_Bimbingan
    SET Status = @Status
    WHERE ID_Log = @ID_Log
      AND Status IN ('Disetujui', 'Revisi', 'Menunggu');
END;
GO

GRANT EXECUTE ON aktivitas.usp_UpdateStatusBimbingan TO role_dosen;
GO


-- DENY (Minimal 2 Izin)
-- DENY 1: Semua role NON-ADMIN tidak boleh DELETE data apapun
-- Mencegah penghapusan data yang tidak disengaja maupun disengaja
DENY DELETE ON SCHEMA::master    TO role_staf;
DENY DELETE ON SCHEMA::akademik  TO role_staf;
DENY DELETE ON SCHEMA::aktivitas TO role_staf;
GO

DENY DELETE ON SCHEMA::master    TO role_dosen;
DENY DELETE ON SCHEMA::akademik  TO role_dosen;
DENY DELETE ON SCHEMA::aktivitas TO role_dosen;
GO

DENY DELETE ON SCHEMA::master    TO role_auditor;
DENY DELETE ON SCHEMA::akademik  TO role_auditor;
DENY DELETE ON SCHEMA::aktivitas TO role_auditor;
GO

DENY DELETE ON SCHEMA::master    TO role_mahasiswa;
DENY DELETE ON SCHEMA::akademik  TO role_mahasiswa;
DENY DELETE ON SCHEMA::aktivitas TO role_mahasiswa;
GO

-- DENY 2: role_dosen tidak boleh melihat atau mengubah data master
-- (Data Mahasiswa, Dosen lain, Staff_TU bersifat konfidensial)
DENY SELECT ON SCHEMA::master TO role_dosen;
DENY INSERT ON SCHEMA::master TO role_dosen;
DENY UPDATE ON SCHEMA::master TO role_dosen;
GO

-- DENY 3: role_auditor tidak boleh INSERT, UPDATE, DELETE apapun
-- Memastikan auditor benar-benar hanya read-only
DENY INSERT ON SCHEMA::master    TO role_auditor;
DENY INSERT ON SCHEMA::akademik  TO role_auditor;
DENY INSERT ON SCHEMA::aktivitas TO role_auditor;

DENY UPDATE ON SCHEMA::master    TO role_auditor;
DENY UPDATE ON SCHEMA::akademik  TO role_auditor;
DENY UPDATE ON SCHEMA::aktivitas TO role_auditor;
GO

-- DENY 4: role_mahasiswa tidak boleh akses tabel langsung
-- Mahasiswa HANYA boleh akses lewat VIEW yang sudah disediakan
DENY SELECT ON master.Mahasiswa                   TO role_mahasiswa;
DENY SELECT ON master.Dosen                       TO role_mahasiswa;
DENY SELECT ON master.Staff_TU                    TO role_mahasiswa;
DENY SELECT ON akademik.Monitoring_TA             TO role_mahasiswa;
DENY SELECT ON akademik.Pengajuan_Pendadaran      TO role_mahasiswa;
DENY SELECT ON aktivitas.Log_Bimbingan            TO role_mahasiswa;
DENY INSERT ON akademik.Monitoring_TA             TO role_mahasiswa;
DENY INSERT ON akademik.Pengajuan_Pendadaran      TO role_mahasiswa;
DENY UPDATE ON akademik.Pengajuan_Pendadaran      TO role_mahasiswa;
GO


-- REVOKE (Minimal 1 Izin)
-- Skenario REVOKE 1:
-- Sebelumnya role_staf sempat diberikan hak UPDATE pada tabel
-- master.Dosen secara langsung (grant individual ke tabel).
-- Setelah evaluasi, keputusan diubah: staf tidak perlu update
-- data dosen langsung — harus melalui prosedur resmi.
-- Maka GRANT UPDATE pada tabel Dosen di-REVOKE.

-- Simulasi: dulu staf diberi hak UPDATE langsung ke tabel Dosen
GRANT UPDATE ON master.Dosen TO role_staf;
GO

-- Verifikasi sebelum revoke
SELECT 
    dp.name         AS Grantee,
    o.name          AS ObjectName,
    p.permission_name,
    p.state_desc
FROM sys.database_permissions p
JOIN sys.database_principals  dp ON p.grantee_principal_id = dp.principal_id
JOIN sys.objects               o  ON p.major_id             = o.object_id
WHERE dp.name = 'role_staf'
  AND o.name  = 'Dosen';
GO

-- REVOKE hak UPDATE pada tabel Dosen dari role_staf
REVOKE UPDATE ON master.Dosen FROM role_staf;
GO

-- Verifikasi setelah revoke (harusnya kosong / tidak muncul)
SELECT 
    dp.name         AS Grantee,
    o.name          AS ObjectName,
    p.permission_name,
    p.state_desc
FROM sys.database_permissions p
JOIN sys.database_principals  dp ON p.grantee_principal_id = dp.principal_id
JOIN sys.objects               o  ON p.major_id             = o.object_id
WHERE dp.name = 'role_staf'
  AND o.name  = 'Dosen'
  AND p.permission_name = 'UPDATE';
GO

-- Skenario REVOKE 2:
-- UserDosen sempat diberikan hak SELECT langsung ke tabel
-- master.Mahasiswa untuk keperluan darurat (lihat NIM mahasiswanya).
-- Setelah fitur VIEW tersedia, hak langsung ini di-REVOKE.
GRANT SELECT ON master.Mahasiswa TO UserDosen;
GO

-- Setelah VIEW tersedia, cabut hak langsung tersebut
REVOKE SELECT ON master.Mahasiswa FROM UserDosen;
GO


-- VERIFIKASI AKHIR SEMUA PERMISSION
-- Lihat semua GRANT dan DENY yang berlaku per role/user
SELECT 
    dp.name             AS Grantee,
    p.class_desc        AS TargetType,
    ISNULL(s.name, '')  AS SchemaName,
    ISNULL(o.name, '')  AS ObjectName,
    p.permission_name   AS Permission,
    p.state_desc        AS State
FROM sys.database_permissions p
JOIN sys.database_principals  dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects          o  ON p.major_id = o.object_id
LEFT JOIN sys.schemas          s  ON o.schema_id = s.schema_id
WHERE dp.name IN ('role_dosen', 'role_staf', 'role_auditor', 'role_mahasiswa', 'UserDosen')
  AND p.state_desc IN ('GRANT', 'DENY')
ORDER BY dp.name, p.state_desc, p.class_desc, s.name, o.name, p.permission_name;
GO

-- Cek permission efektif untuk UserStaf (termasuk yang diwarisi dari role)
EXECUTE AS USER = 'UserStaf';
    SELECT HAS_PERMS_BY_NAME('master.Mahasiswa',   'OBJECT', 'SELECT') AS CanSelect_Mahasiswa,
           HAS_PERMS_BY_NAME('master.Mahasiswa',   'OBJECT', 'INSERT') AS CanInsert_Mahasiswa,
           HAS_PERMS_BY_NAME('master.Mahasiswa',   'OBJECT', 'UPDATE') AS CanUpdate_Mahasiswa,
           HAS_PERMS_BY_NAME('master.Mahasiswa',   'OBJECT', 'DELETE') AS CanDelete_Mahasiswa;
REVERT;
GO

-- Cek permission efektif untuk UserAuditor
EXECUTE AS USER = 'UserAuditor';
    SELECT HAS_PERMS_BY_NAME('akademik.Monitoring_TA',        'OBJECT', 'SELECT') AS CanSelect_MonTA,
           HAS_PERMS_BY_NAME('akademik.Pengajuan_Pendadaran', 'OBJECT', 'INSERT') AS CanInsert_Pendadaran,
           HAS_PERMS_BY_NAME('akademik.Pengajuan_Pendadaran', 'OBJECT', 'UPDATE') AS CanUpdate_Pendadaran,
           HAS_PERMS_BY_NAME('akademik.Pengajuan_Pendadaran', 'OBJECT', 'DELETE') AS CanDelete_Pendadaran;
REVERT;
GO

-- Cek permission efektif untuk UserMahasiswa
EXECUTE AS USER = 'UserMahasiswa';
    SELECT HAS_PERMS_BY_NAME('akademik.vw_TA_Mahasiswa',           'OBJECT', 'SELECT') AS CanSelect_ViewTA,
           HAS_PERMS_BY_NAME('akademik.Monitoring_TA',             'OBJECT', 'SELECT') AS CanSelect_TabelTA,
           HAS_PERMS_BY_NAME('aktivitas.vw_LogBimbingan_Mahasiswa','OBJECT', 'SELECT') AS CanSelect_ViewLog,
           HAS_PERMS_BY_NAME('aktivitas.Log_Bimbingan',            'OBJECT', 'SELECT') AS CanSelect_TabelLog;
REVERT;
GO

-- ======================================================
-- STUDI KASUS, SKENARIO DAN PENJELASAN SEMUA ADA DI WORD
-- ======================================================