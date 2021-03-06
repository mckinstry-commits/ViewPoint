SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[vpspGenerateSP] (
 @server varchar(30) = null,
 @uname varchar(30) = null,
 @pwd varchar(30) = null,
 @dbname varchar(30) = null,
 @filename varchar(200) = 'c:\script.sql'
)
AS

DECLARE @object int
DECLARE @hr int
DECLARE @return varchar(200)
DECLARE @exec_str varchar(2000)
DECLARE @spname sysname

SET NOCOUNT ON

-- Sets the server to the local server
IF @server is NULL
 SELECT @server = @@servername

-- Sets the database to the current database
IF @dbname is NULL
 SELECT @dbname = db_name()

-- Sets the username to the current user name
IF @uname is NULL
 SELECT @uname = SYSTEM_USER

-- Create an object that points to the SQL Server
EXEC @hr = sp_OACreate 'SQLDMO.SQLServer', @object OUT
IF @hr <> 0
BEGIN
 PRINT 'error create SQLOLE.SQLServer'
 RETURN
END

-- Connect to the SQL Server
IF @pwd is NULL
 BEGIN
  EXEC @hr = sp_OAMethod @object, 'Connect', NULL, @server, @uname
  IF @hr <> 0
   BEGIN
    PRINT 'error Connect'
    RETURN
   END
 END
ELSE
 BEGIN
  EXEC @hr = sp_OAMethod @object, 'Connect', NULL, @server, @uname, @pwd
  IF @hr <> 0
   BEGIN
    PRINT 'error Connect'
    RETURN
   END
 END

--Verify the connection
EXEC @hr = sp_OAMethod @object, 'VerifyConnection', @return OUT
IF @hr <> 0
BEGIN
 PRINT 'error VerifyConnection'
 RETURN
END

SET @exec_str = 'DECLARE script_cursor CURSOR FOR SELECT name FROM ' + @dbname + '..sysobjects WHERE type = ''P'' ORDER BY name'
EXEC (@exec_str)

OPEN script_cursor
FETCH NEXT FROM script_cursor INTO @spname
WHILE (@@fetch_status <> -1)
BEGIN
 SET @exec_str = 'Databases("'+ @dbname +'").StoredProcedures("'+RTRIM(UPPER(@spname))+'").Script(74077,"'+ @filename +'")'
 EXEC @hr = sp_OAMethod @object, @exec_str, @return OUT
 IF @hr <> 0
  BEGIN
   PRINT 'error Script'
   RETURN  
  END
 FETCH NEXT FROM script_cursor INTO @spname
END
CLOSE script_cursor
DEALLOCATE script_cursor
 
-- Destroy the object
EXEC @hr = sp_OADestroy @object
IF @hr <> 0
BEGIN
 PRINT 'error destroy object'
 RETURN
END


GO
GRANT EXECUTE ON  [dbo].[vpspGenerateSP] TO [VCSPortal]
GO
