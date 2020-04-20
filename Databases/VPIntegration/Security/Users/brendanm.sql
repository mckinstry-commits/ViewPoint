IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'brendanm')
CREATE LOGIN [brendanm] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [brendanm] FOR LOGIN [brendanm]
GO
GRANT CONNECT TO [brendanm]
