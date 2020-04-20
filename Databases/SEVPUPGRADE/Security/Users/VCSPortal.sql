IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'VCSPortal')
CREATE LOGIN [VCSPortal] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [VCSPortal] FOR LOGIN [VCSPortal]
GO
