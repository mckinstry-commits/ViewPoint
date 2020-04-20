IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'MCKINSTRY\ViewPointTestUsers')
CREATE LOGIN [MCKINSTRY\ViewPointTestUsers] FROM WINDOWS
GO
CREATE USER [MCKINSTRY\ViewPointTestUsers] FOR LOGIN [MCKINSTRY\ViewPointTestUsers]
GO
