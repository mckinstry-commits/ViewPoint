IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'vcspublic')
CREATE LOGIN [vcspublic] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [vcspublic] FOR LOGIN [vcspublic]
GO
GRANT CONNECT TO [vcspublic]
