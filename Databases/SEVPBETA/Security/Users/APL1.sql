IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'APL1')
CREATE LOGIN [APL1] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [APL1] FOR LOGIN [APL1]
GO