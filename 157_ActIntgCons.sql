--MEMBUAT DATABASE + FILEGROUP + FILE
CREATE DATABASE UniversitasDB
ON PRIMARY (
    NAME = UniversitasDB_Data,
    FILENAME = 'D:\SQLData\UniversitasDB_Data.mdf',
    SIZE = 10MB,
    FILEGROWTH = 5MB
),

FILEGROUP AkademikGroup (
    NAME = Akademik_Data,
    FILENAME = 'D:\SQLData\Akademik_Data.ndf',
    SIZE = 10MB,
    FILEGROWTH = 5MB
)

LOG ON
(
    NAME = UniversitasDB_Log,
    FILENAME = 'D:\SQLData\UniversitasDB_Log.ldf',
    SIZE = 5MB,
    FILEGROWTH = 5MB
);
GO


USE UniversitasDB;
GO


--MEMBUAT SCHEMA

CREATE SCHEMA akademik;
GO

CREATE SCHEMA sdm;
GO

CREATE SCHEMA keuangan;
GO


--TABEL MAHASISWA
CREATE TABLE akademik.Mahasiswa_A (
    NIM VARCHAR(11) PRIMARY KEY,
    Nama VARCHAR(100) NOT NULL,
    Alamat VARCHAR(200),
    NoHP VARCHAR(15),
    TanggalLahir DATE,
    Email VARCHAR(100) UNIQUE
);
GO


--TABEL DOSEN
CREATE TABLE sdm.Dosen_A (
    NIDN VARCHAR(10) PRIMARY KEY,
    Nama VARCHAR(100) NOT NULL,
    Jabatan VARCHAR(50),
    Gaji DECIMAL(12,2),
    TanggalMasuk DATE,

    CONSTRAINT CK_Gaji CHECK (Gaji > 0)
);
GO


--TABEL PEMBAYARAN
CREATE TABLE keuangan.Pembayaran (
    ID_Pembayaran INT,
    NIM VARCHAR(11),
    TanggalBayar DATE,
    Jumlah DECIMAL(12,2),
    Status VARCHAR(20),

    CONSTRAINT PK_Pembayaran 
    PRIMARY KEY (ID_Pembayaran),

    CONSTRAINT FK_Pembayaran_Mahasiswa
    FOREIGN KEY (NIM)
    REFERENCES akademik.Mahasiswa_A(NIM),

    CONSTRAINT CK_Jumlah_Pembayaran
    CHECK (Jumlah > 0),

    CONSTRAINT DF_Status_Pembayaran
    DEFAULT 'Belum Lunas' FOR Status
);
GO


--INSERT DATA MAHASISWA
INSERT INTO akademik.Mahasiswa_A
VALUES
('20250140157','Ahmad Rassya Maulana','Kalimantan Tengah','082246974812','2007-04-10','rrassya19@email.com'),
('20250140175','Muhammad Rehan Arfa','Kalimantan Selatan','082246974821','2007-11-20','rehan234@email.com');
GO


--INSERT DATA DOSEN
INSERT INTO sdm.Dosen_A
VALUES
('0518048401','Apriliya Kurnianti, S.T., M.Eng','Lektor',12000000,'2015-04-10'),
('0707108402','Chayadi Oktomy N S, S.T., M.Eng., P.hD.','Asisten Ahli',12000000,'2011-08-01');
GO


--INSERT DATA PEMBAYARAN DEFAULT STATUS = Belum Lunas
INSERT INTO keuangan.Pembayaran
(ID_Pembayaran,NIM,TanggalBayar,Jumlah)

VALUES
(01,'20250140157','2026-03-11',2000000),
(02,'20250140175','2026-03-12',1500000);
GO


--MELIHAT DATA
SELECT * FROM akademik.Mahasiswa_A;
SELECT * FROM sdm.Dosen_A;
SELECT * FROM keuangan.Pembayaran;
GO


--MENGFHAPUS NIM DITABEL MAHASISWA
DELETE FROM akademik.Mahasiswa_A
WHERE NIM = '20250140175';
GO