IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'billo')
CREATE LOGIN [billo] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [billo] FOR LOGIN [billo]
GO
GRANT CONNECT TO [billo]
