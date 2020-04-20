IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'viewpointcs')
CREATE LOGIN [viewpointcs] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [viewpointcs] FOR LOGIN [viewpointcs]
GO
GRANT CONNECT TO [viewpointcs]
