IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'MCKINSTRY\viewpointsvc')
CREATE LOGIN [MCKINSTRY\viewpointsvc] FROM WINDOWS
GO
CREATE USER [MCKINSTRY\viewpointsvc] FOR LOGIN [MCKINSTRY\viewpointsvc]
GO
