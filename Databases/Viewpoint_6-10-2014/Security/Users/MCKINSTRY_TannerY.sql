IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'MCKINSTRY\TannerY')
CREATE LOGIN [MCKINSTRY\TannerY] FROM WINDOWS
GO
CREATE USER [MCKINSTRY\TannerY] FOR LOGIN [MCKINSTRY\TannerY] WITH DEFAULT_SCHEMA=[MCKINSTRY\TannerY]
GO
REVOKE CONNECT TO [MCKINSTRY\TannerY]
GRANT CREATE PROCEDURE TO [MCKINSTRY\TannerY]