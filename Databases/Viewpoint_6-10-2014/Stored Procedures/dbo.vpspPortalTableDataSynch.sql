SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPortalTableDataSynch]
/********************************
* Created: Jeremiah Barkley
* Modified: AR - 2/17/2011 - 142350 - supporting multiple collations
			AR - 4/5/2011 - 142200 - adding brackets around database and table objects
			JR - 3/12/2013 Adding an optional parameter of the source database.
*
* Synchronize the data of the specified table between two databases. 
* The procedure does not delete any rows from the destination database.
*
* @SourceDB:			The source database name of the data to synchronize.
* @DestinationDB:		The destination database name to synch to.
* @TableName:			The name of the table to synchronize.
* @KeyColumn:			The column name of the key column.
* @UniqueIndexColumn:	The column name of the unique index column.  Leave NULL if none exists.
*
* Return code:
* @rcode - anything except 0 indicates an error
*
*********************************/
(
	@SourceDB VARCHAR(100),
	@SourceServer VARCHAR(100) = '',
	@DestinationDB VARCHAR(100),
	@TableName VARCHAR(100),
	@KeyColumn VARCHAR(100),
	@UniqueIndexColumn VARCHAR(100) = NULL
)
AS

	DECLARE @SQLString VARCHAR(2000), @ExecuteString NVARCHAR(2000), @UpdateColumnsString VARCHAR(MAX), @InsertColumnsString VARCHAR(MAX)
	
	SET @SourceServer = [dbo].[vfFormatServerName](@SourceServer);
	
	SELECT @UpdateColumnsString = STUFF((SELECT ', ' + '[' + sys.columns.name + '] = s.[' + sys.columns.name + ']' FROM sys.columns INNER JOIN sys.tables ON sys.tables.object_id = sys.columns.object_id WHERE sys.tables.name = @TableName AND NOT sys.columns.name LIKE @KeyColumn FOR XML PATH('')), 1, 2, '')
	SELECT @InsertColumnsString = STUFF((SELECT ', [' + sys.columns.name + ']' FROM sys.columns INNER JOIN sys.tables ON sys.tables.object_id = sys.columns.object_id WHERE sys.tables.name = @TableName FOR XML PATH('')), 1, 2, '')
	
	-- adding some collation stuff for column compares
	DECLARE @destCollation AS varchar(128)
	DECLARE @srcCollation AS varchar(128)
	-- pull the source and dest collations from the database
	SELECT @srcCollation = collation_name FROM sys.databases WHERE [name] = @SourceDB
	SELECT @destCollation = collation_name FROM sys.databases WHERE [name] = @DestinationDB	
	
	IF EXISTS (SELECT 1
				FROM sys.tables AS t
						JOIN sys.columns AS c ON t.object_id = c.object_id
						JOIN sys.types AS t2 ON c.user_type_id = t2.user_type_id
				WHERE t.name = @TableName
					AND c.name = @UniqueIndexColumn
					AND t2.name NOT IN('varchar','nvarchar','char','nchar')
				)
		OR	@srcCollation = @destCollation
	BEGIN
	   SET @destCollation = ''
	END
	ELSE
	BEGIN
	   SET @destCollation = ' COLLATE ' + @destCollation
	END

	-- Update existing rows under 50000
	SET @SQLString = 'UPDATE ' + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName) 
		+ ' SET ' + @UpdateColumnsString 
		+ ' FROM ' + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName) + ' d'
		+ ' INNER JOIN ' + @SourceServer + QUOTENAME(@SourceDB) + '.[dbo].' + QUOTENAME(@TableName) + ' s'
		+ ' ON s.' + @KeyColumn 
		+ ' = d.' + @KeyColumn 
		+ ' WHERE d.' + @KeyColumn + ' < 50000; '
		
		
	SELECT @ExecuteString = CAST(@SQLString AS NVARCHAR(2000))
	BEGIN TRY
	
		BEGIN TRAN
		EXEC sp_executesql @ExecuteString
				
		
		-- Insert depending on if there is a unique index column			
		IF (@UniqueIndexColumn IS NULL)
			BEGIN
				-- Insert missing rows under 50000
				SET @SQLString = 'SET IDENTITY_INSERT ' + QUOTENAME(@DestinationDB) + '.[dbo].' + @TableName + ' ON; '
				SET @SQLString = @SQLString + 'INSERT INTO ' + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName)
					+ ' (' + @InsertColumnsString + ')'
					+ ' (SELECT ' + @InsertColumnsString 
					+ ' FROM ' + @SourceServer + QUOTENAME(@SourceDB) + '.[dbo].' + QUOTENAME(@TableName) + ' s'
					+ ' WHERE s.' + @KeyColumn + ' < 50000'
					+ ' AND s.' + @KeyColumn + ' NOT IN (SELECT ' + @KeyColumn 
					+ ' FROM ' + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName) + '));'
				
				SET @SQLString = @SQLString + ' SET IDENTITY_INSERT ' + QUOTENAME(@DestinationDB) + '.[dbo].' + @TableName + ' OFF'
				Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
				
				exec sp_executesql @ExecuteString
			END
		ELSE
			BEGIN
				-- First update any custom rows that may share a unique key with a non-custom row
				SET @SQLString = 'UPDATE ' + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName) 
					+ ' SET ' + @UniqueIndexColumn + ' = ' + @UniqueIndexColumn + ' + '' (Custom)'''
					+ ' WHERE ' + @UniqueIndexColumn + ' IN (SELECT ' + @UniqueIndexColumn  + @destCollation
					+ ' FROM ' + @SourceServer + QUOTENAME(@SourceDB) + '.[dbo].' + QUOTENAME(@TableName) + ' s'
					+ ' WHERE NOT EXISTS (SELECT ' + @KeyColumn 
					+ ' FROM ' + QUOTENAME(@DestinationDB) + '.[dbo].' + @TableName 
					+ ' WHERE ' + @KeyColumn + ' = s.' + @KeyColumn 
					+ ' AND ' + @UniqueIndexColumn + ' = s.' + @UniqueIndexColumn + @destCollation + ')' 
					+ ' AND s.' + @KeyColumn + ' < 50000 AND s.Static = 1)'
					+ ' AND ' + @KeyColumn + '>= 50000; '
				
				-- Insert missing rows under 50000
				SET @SQLString = @SQLString + 'SET IDENTITY_INSERT ' + QUOTENAME(@DestinationDB) + '.[dbo].' + @TableName + ' ON;'
				SET @SQLString = @SQLString + ' INSERT INTO ' + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName) 
					+ ' (' + @InsertColumnsString + ') (SELECT ' + @InsertColumnsString
					+ ' FROM ' + @SourceServer + QUOTENAME(@SourceDB) + '.[dbo].' + QUOTENAME(@TableName) + ' s'
					+ ' WHERE NOT EXISTS (SELECT ' + @KeyColumn  
					+ ' FROM ' + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName) 
					+ ' WHERE ' + @KeyColumn + ' = s.' + @KeyColumn 
					+ ' AND ' + @UniqueIndexColumn + ' = s.' + @UniqueIndexColumn + @destCollation + ') AND s.' + @KeyColumn + ' < 50000 AND s.Static = 1);'

				SET @SQLString = @SQLString + ' SET IDENTITY_INSERT ' + QUOTENAME(@DestinationDB) + '.[dbo].' + @TableName + ' OFF'
				SELECT @ExecuteString = CAST(@SQLString AS NVarchar(2000))
				
				EXEC sp_executesql @ExecuteString
			END

		COMMIT
		RETURN
	 END TRY
	 BEGIN CATCH			
		IF @@TRANCOUNT <> 0
		BEGIN
			ROLLBACK
		END
		DECLARE @Err varchar(MAX)
		SET @Err = ERROR_MESSAGE()
		PRINT N'An error occurred performing identity insert in ' + @TableName + ' ' + @Err;
		SELECT -1
		RETURN 
	END CATCH

GO
GRANT EXECUTE ON  [dbo].[vpspPortalTableDataSynch] TO [VCSPortal]
GO
