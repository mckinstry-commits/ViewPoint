SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPortalImportDataNonIdentity]
 /********************************
* Created: Tim Stevens - 01/27/2009
* Modified: AR - 142200 - adding brackets around database and table objects
*           JayR 2013-03-13  Add an additional parameter of SourceServer so we can cross DB Links
*
* Used by VPUpdate.exe to move data from source database to target database
* for the VP Connects product
*
* Return code:
* @rcode - anything except 0 indicates an error
* 01/27/2009 - TMS - Added [public] userid to grant of execute
*
*********************************/
(
  @SourceDB varchar(100),
  @SourceServer VARCHAR(100) = '',
  @TableName varchar(100)
)
AS 
DECLARE @SQLString varchar(1000),
    @ExecuteString nvarchar(1000)

SET @SourceServer = [dbo].[vfFormatServerName](@SourceServer);
		
BEGIN TRY
	BEGIN TRAN
	SET @SQLString = 'INSERT ' + QUOTENAME(@TableName) + ' SELECT * FROM '
		+ @SourceServer + QUOTENAME(@SourceDB) + '.dbo.' + QUOTENAME(@TableName)
	SELECT  @ExecuteString = CAST(@SQLString AS nvarchar(1000))
	EXEC sp_executesql @ExecuteString
	
	COMMIT
END TRY
BEGIN CATCH
    IF @@TRANCOUNT <> 0
    BEGIN
        ROLLBACK
    END
    
    PRINT N'An error occurred inserting data in ' + @TableName + ERROR_MESSAGE();
    RETURN -1
END CATCH
GO
GRANT EXECUTE ON  [dbo].[vpspPortalImportDataNonIdentity] TO [VCSPortal]
GO
