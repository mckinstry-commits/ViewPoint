SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/20/2014
-- Description:	Kill Connections by User
-- =============================================
CREATE PROCEDURE [dbo].[mckKillConnectionsByUser] 
	-- Add the parameters for the stored procedure here
	@username varchar(MAX) = ''
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @spid int
    DECLARE @sql varchar(MAX)
 
    DECLARE cur CURSOR FOR
        SELECT spid FROM sys.sysprocesses P
            JOIN sys.sysdatabases D ON (D.dbid = P.dbid)
            JOIN sys.sysusers U ON (P.uid = U.uid)
            WHERE loginame = @username
            AND P.spid != @@SPID
 
    OPEN cur
 
    FETCH NEXT FROM cur
        INTO @spid
         
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT CONVERT(varchar, @spid)
 
        SET @sql = 'KILL ' + RTRIM(@spid)
        PRINT @sql
        EXEC(@sql)
 
        FETCH NEXT FROM cur
            INTO @spid
    END
 
    CLOSE cur
    DEALLOCATE cur
GO
GRANT EXECUTE ON  [dbo].[mckKillConnectionsByUser] TO [public]
GO
