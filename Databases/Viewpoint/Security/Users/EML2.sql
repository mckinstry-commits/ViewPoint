IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'EML2')
CREATE LOGIN [EML2] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [EML2] FOR LOGIN [EML2]
GO
