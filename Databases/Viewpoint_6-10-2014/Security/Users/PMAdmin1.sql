IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'PMAdmin1')
CREATE LOGIN [PMAdmin1] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [PMAdmin1] FOR LOGIN [PMAdmin1]
GO
