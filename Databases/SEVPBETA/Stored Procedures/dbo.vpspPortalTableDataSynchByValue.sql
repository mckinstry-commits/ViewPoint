SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************
* Created: Jeremiah Barkley
* Modified: 
*
* Insert data from the source database into the destination database where the compare column
* value is equal to the compare value.
*
* @SourceDB:			The source database name of the data to synchronize.
* @DestinationDB:		The destination database name to synch to.
* @TableName:			The name of the table to synchronize.
* @CompareColumn:		The name of the column to compare.
* @CompareValue:		The value to compare against.
*
* Return code:
* @rcode - anything except 0 indicates an error
*
*********************************/
CREATE PROCEDURE [dbo].[vpspPortalTableDataSynchByValue]
(
	@SourceDB VARCHAR(100),
	@DestinationDB VARCHAR(100),
	@TableName VARCHAR(100),
	@KeyColumn VARCHAR(100),
	@CompareColumn VARCHAR(100),
	@CompareValue VARCHAR(100) = NULL
)
AS
BEGIN TRY
	BEGIN TRAN
	  DECLARE @SQLString VARCHAR(1000), @ExecuteString NVARCHAR(1000), @InsertColumnsString VARCHAR(MAX)
		SELECT @InsertColumnsString = STUFF((SELECT ', [' + sys.columns.name + ']' FROM sys.columns INNER JOIN sys.tables ON sys.tables.object_id = sys.columns.object_id WHERE sys.tables.name = @TableName FOR XML PATH('')), 1, 2, '')
		
		SET @SQLString = ''
		-- make sure we have an identity before setting the condition		
		IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = object_id(@TableName) AND is_identity = 1)
		BEGIN
			SET @SQLString = 'SET IDENTITY_INSERT ' + @TableName + ' ON; '
		END
		-- Insert rows where a specified compare column equals the compare value
		SET @SQLString = @SQLString + 'INSERT INTO ' + @DestinationDB + '.[dbo].' + @TableName
			+ ' (' + @InsertColumnsString + ')'
			+ ' (SELECT ' + @InsertColumnsString 
			+ ' FROM ' + @SourceDB + '.[dbo].' + @TableName + ' s'
			+ ' WHERE s.' + @CompareColumn + ' = ' + @CompareValue
			+ ' AND s.' + @KeyColumn + ' NOT IN (SELECT ' + @KeyColumn 
			+ ' FROM ' + @DestinationDB + '.[dbo].' + @TableName + '));'
		
		-- make sure we have an identity before setting the condition		
		IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = object_id(@TableName) AND is_identity = 1)
		BEGIN
			SET @SQLString = @SQLString + ' SET IDENTITY_INSERT ' + @TableName + ' OFF'
		END
		
		SELECT @ExecuteString = CAST(@SQLString AS NVARCHAR(1000))
		EXEC sp_executesql @ExecuteString;
	COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 BEGIN ROLLBACK END
			PRINT ERROR_MESSAGE()
			PRINT N'An error occurred performing identity insert in ' + @TableName;
			SELECT -1
			RETURN 
END CATCH



GO
GRANT EXECUTE ON  [dbo].[vpspPortalTableDataSynchByValue] TO [VCSPortal]
GO
