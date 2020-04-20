IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'tracyf')
CREATE LOGIN [tracyf] WITH PASSWORD = 'p@ssw0rd'
GO
CREATE USER [tracyf] FOR LOGIN [tracyf]
GO
GRANT CREATE PROCEDURE TO [tracyf]
GRANT CREATE VIEW TO [tracyf]
GRANT EXECUTE TO [tracyf] WITH GRANT OPTION
