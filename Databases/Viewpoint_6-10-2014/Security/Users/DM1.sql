IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'DM1')
CREATE LOGIN [DM1] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [DM1] FOR LOGIN [DM1]
GO