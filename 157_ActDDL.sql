
--MEMBUAT DATABASE 
CREATE DATABASE D_Monitoring_TA
ON PRIMARY (
    NAME = [157_D_Monitoring_TA],   --Primary File             
    FILENAME = 'D:\SQLData\157_D_TA.mdf', 
    SIZE = 10MB,
    FILEGROWTH = 5MB
)
LOG ON (
    NAME = 'R_D_Monitoring_TA_Log',   --Log file      
    FILENAME = 'D:\SQLData\R_D_Monitoring_TA_Log.ldf', 
    SIZE = 5MB,
    FILEGROWTH = 5MB
);
GO

--MENAMBAH FILEGROUP & SECONDARY FILE
ALTER DATABASE D_Monitoring_TA ADD FILEGROUP FG_Monitoring_TA; 

ALTER DATABASE D_Monitoring_TA   
ADD FILE (
    NAME = 'ARM_D_Monitoring_TA',
    FILENAME = 'D:\SQLData\ARM_D_Monitoring_TA.ndf', 
    SIZE = 5MB
) TO FILEGROUP FG_Monitoring_TA;    
GO

USE D_Monitoring_TA;
GO

--MEMBUAT 3 SCHEMA BERBEDA
CREATE SCHEMA akademik;   
GO

CREATE SCHEMA aktivitas;  
GO

CREATE SCHEMA arsip;   
GO

SELECT name --nama kolom
FROM sys.schemas; --nama tabel

--TABEL MAHASISWA
CREATE TABLE akademik.Mahasiswa (
    Nim CHAR(11) PRIMARY KEY,
    Nama VARCHAR(100) NOT NULL,
    Jurusan VARCHAR(50),
    Angkatan INT
);

--MEMINDAHKAN KEPEMILIKAN TABEL MAHASISWA DARI SCHEMA AKDEMIK KE SCHEMA AKTIVITAS
ALTER SCHEMA aktivitas
TRANSFER akademik.Mahasiswa;
GO

--HAPUS SATU SCHEMA
DROP SCHEMA arsip; 
GO
