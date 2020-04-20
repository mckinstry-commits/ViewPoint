IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'IntegrationAccount')
CREATE LOGIN [IntegrationAccount] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [IntegrationAccount] FOR LOGIN [IntegrationAccount]
GO
GRANT INSERT TO [IntegrationAccount]
GRANT SELECT TO [IntegrationAccount]
GRANT UPDATE TO [IntegrationAccount]
