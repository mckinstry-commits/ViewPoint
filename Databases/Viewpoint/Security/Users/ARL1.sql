IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'ARL1')
CREATE LOGIN [ARL1] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [ARL1] FOR LOGIN [ARL1]
GO