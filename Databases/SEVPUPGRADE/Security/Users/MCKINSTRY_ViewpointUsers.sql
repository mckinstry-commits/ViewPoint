IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'MCKINSTRY\ViewpointUsers')
CREATE LOGIN [MCKINSTRY\ViewpointUsers] FROM WINDOWS
GO
CREATE USER [MCKINSTRY\ViewpointUsers] FOR LOGIN [MCKINSTRY\ViewpointUsers]
GO
