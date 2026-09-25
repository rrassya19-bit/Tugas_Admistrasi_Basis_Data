
-- Pengujian Alert
BACKUP DATABASE KampusPraktikum
TO DISK = 'Z:\FolderTidakAda\Backup.bak'
/*
Backup akan gagal dan error 3013 akan muncul...

Akibatnya:
-SQL Server tidak menemukan folder tersebut.
-Muncul Error 3201.
-SQL Server mengeluarkan Error 3013.
-Alert yang Anda buat dengan Error Number = 3013 akan terpicu.

Msg 3201, Level 16, State 1, Line 3
Cannot open backup device 'Z:\FolderTidakAda\Backup.bak'. Operating system error 3(The system cannot find the path specified.).
Msg 3013, Level 16, State 1, Line 3
BACKUP DATABASE is terminating abnormally.

Completion time: 2026-06-03T14:51:52.4152985+07:00
*/