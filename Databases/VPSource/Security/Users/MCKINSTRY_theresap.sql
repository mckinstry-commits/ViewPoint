IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'MCKINSTRY\theresap')
CREATE LOGIN [MCKINSTRY\theresap] FROM WINDOWS
GO
CREATE USER [MCKINSTRY\theresap] FOR LOGIN [MCKINSTRY\theresap]
GO
