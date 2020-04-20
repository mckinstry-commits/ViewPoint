IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'AsteaIntegration')
CREATE LOGIN [AsteaIntegration] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [AsteaIntegration] FOR LOGIN [AsteaIntegration]
GO
