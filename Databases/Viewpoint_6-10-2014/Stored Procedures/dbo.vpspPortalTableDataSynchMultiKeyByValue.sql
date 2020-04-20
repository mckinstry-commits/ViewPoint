SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************
* Created: Jeremiah Barkley
* Modified: JayR 2013-03-13  Add an additional parameter of SourceServer so we can cross DB Links
*
* Insert data from the source database into the destination database where the compare column
* value equals the compare value.  This method is used when there is a multipart key.
*
* @SourceDB:			The source database name of the data to synchronize.
* @DestinationDB:		The destination database name to synch to.
* @TableName:			The name of the table to synchronize.
* @CompareColumn:		The name of the column to compare.
* @CompareValue:		The value to compare against.
* @KeyColumn1:			The first key column name.
* @KeyColumn2:			The second key column name. (Optional)
* @KeyColumn3:			The third key column name. (Optional)
*
* Return code:
* @rcode - anything except 0 indicates an error
*
*********************************/
CREATE PROCEDURE [dbo].[vpspPortalTableDataSynchMultiKeyByValue]
(
	@SourceDB VARCHAR(100),
	@SourceServer VARCHAR(100) = '',
	@DestinationDB VARCHAR(100),
	@TableName VARCHAR(100),
	@CompareColumn VARCHAR(100),
	@CompareValue VARCHAR(100),
	@KeyColumn1 VARCHAR(100),
	@KeyColumn2 VARCHAR(100) = NULL,
	@KeyColumn3 VARCHAR(100) = NULL
)
AS

	DECLARE @SQLString VARCHAR(1000), @ExecuteString NVARCHAR(1000), @UpdateColumnsString VARCHAR(MAX), @InsertColumnsString VARCHAR(MAX)
BEGIN TRY
BEGIN TRAN

	SET @SourceServer = [dbo].[vfFormatServerName](@SourceServer);

	SELECT @InsertColumnsString = STUFF((SELECT ', [' + sys.columns.name + ']' FROM sys.columns INNER JOIN sys.tables ON sys.tables.object_id = sys.columns.object_id WHERE sys.tables.name = @TableName FOR XML PATH('')), 1, 2, '')

	SET @SQLString = 'INSERT INTO ' + @DestinationDB + '.[dbo].' + @TableName
		+ ' (' + @InsertColumnsString + ')'
		+ ' (SELECT ' + @InsertColumnsString 
		+ ' FROM ' + @SourceServer + @SourceDB + '.[dbo].' + @TableName + ' s'
		+ ' WHERE s.' + @CompareColumn + ' = ' + @CompareValue
		+ ' AND NOT EXISTS (SELECT TOP 1 ' + @KeyColumn1 
		+ ' FROM ' + @DestinationDB + '.[dbo].' + @TableName 
		+ ' WHERE ' + @KeyColumn1 + ' = s.' + @KeyColumn1
	IF (NOT @KeyColumn2 IS NULL) SET @SQLString = @SQLString + ' AND ' + @KeyColumn2 + ' = s.' + @KeyColumn2
	IF (NOT @KeyColumn3 IS NULL) SET @SQLString = @SQLString + ' AND ' + @KeyColumn3 + ' = s.' + @KeyColumn3
	SET @SQLString = @SQLString + '));'
		
	SELECT @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
	EXEC sp_executesql @ExecuteString
	
	COMMIT 
	
END TRY				
BEGIN CATCH
IF @@TRANCOUNT > 0 BEGIN ROLLBACK END
PRINT N'An error occurred performing identity insert in ' + @TableName;
		SELECT -1
			RETURN 
END CATCH

RETURN


GO
GRANT EXECUTE ON  [dbo].[vpspPortalTableDataSynchMultiKeyByValue] TO [VCSPortal]
GO
