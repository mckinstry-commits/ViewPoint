SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPortalTableDataSynchMultiKey]
/********************************
* Created: Jeremiah Barkley
* Modified: AR - 4/5/2011 - 142200 - adding brackets around database and table objects
*
* Synchronize the data of the specified table between two databases. 
* The procedure does not delete any rows from the destination database.
* This procedure will update table using up to three part primary keys.
*
* @SourceDB:			The source database name of the data to synchronize.
* @DestinationDB:		The destination database name to synch to.
* @TableName:			The name of the table to synchronize.
* @KeyColumn1:			The first key column name.
* @KeyColumn2:			The second key column name. (Optional)
* @KeyColumn3:			The third key column name. (Optional)
*
* Return code:
* @rcode - anything except 0 indicates an error
*
*********************************/
(
  @SourceDB varchar(100),
  @DestinationDB varchar(100),
  @TableName varchar(100),
  @KeyColumn1 varchar(100),
  @KeyColumn2 varchar(100) = NULL,
  @KeyColumn3 varchar(100) = NULL
)
AS 
DECLARE @SQLString varchar(1000),
    @ExecuteString nvarchar(1000),
    @UpdateColumnsString varchar(max),
    @InsertColumnsString varchar(max)
BEGIN TRY 
	
    SELECT  @UpdateColumnsString = STUFF(( SELECT   ', ' + '['
                                                    + sys.columns.name
                                                    + '] = s.['
                                                    + sys.columns.name + ']'
                                           FROM     sys.columns
                                                    INNER JOIN sys.tables ON sys.tables.object_id = sys.columns.object_id
                                           WHERE    sys.tables.name = @TableName
                                                    AND NOT sys.columns.name LIKE @KeyColumn1
                                                    AND NOT sys.columns.name LIKE ISNULL(@KeyColumn2,
                                                              '')
                                                    AND NOT sys.columns.name LIKE ISNULL(@KeyColumn3,
                                                              '')
                                         FOR
                                           XML PATH('')
                                         ), 1, 2, '')
    SELECT  @InsertColumnsString = STUFF(( SELECT   ', [' + sys.columns.name
                                                    + ']'
                                           FROM     sys.columns
                                                    INNER JOIN sys.tables ON sys.tables.object_id = sys.columns.object_id
                                           WHERE    sys.tables.name = @TableName
                                         FOR
                                           XML PATH('')
                                         ), 1, 2, '')


	-- Update existing rows under 50000
    SET @SQLString = 'UPDATE ' + QUOTENAME(@DestinationDB) + '.[dbo].'
        + QUOTENAME(@TableName) + ' SET ' + @UpdateColumnsString + ' FROM '
        + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName) + ' d'
        + ' INNER JOIN ' + QUOTENAME(@SourceDB) + '.[dbo].'
        + QUOTENAME(@TableName) + ' s' + ' ON s.' + @KeyColumn1 + ' = d.'
        + @KeyColumn1 
    IF ( NOT @KeyColumn2 IS NULL
       ) 
        SET @SQLString = @SQLString + ' AND s.' + @KeyColumn2 + ' = d.'
            + @KeyColumn2
    IF ( NOT @KeyColumn3 IS NULL
       ) 
        SET @SQLString = @SQLString + ' AND s.' + @KeyColumn3 + ' = d.'
            + @KeyColumn3
    SET @SQLString = @SQLString + ' WHERE d.' + @KeyColumn1 + ' < 50000'
    IF ( NOT @KeyColumn2 IS NULL
       ) 
        SET @SQLString = @SQLString + ' AND d.' + @KeyColumn2 + ' < 50000'
    IF ( NOT @KeyColumn3 IS NULL
       ) 
        SET @SQLString = @SQLString + ' AND d.' + @KeyColumn3 + ' < 50000'
    SET @SQLString = @SQLString + '; '
	
    SELECT  @ExecuteString = CAST(@SQLString AS nvarchar(1000))
    BEGIN TRAN
    EXEC sp_executesql 
        @ExecuteString
	
	-- Insert any missing rows under 50000
    SET @SQLString = 'INSERT INTO ' + QUOTENAME(@DestinationDB) + '.[dbo].'
        + QUOTENAME(@TableName) + ' (' + @InsertColumnsString + ')'
        + ' (SELECT ' + @InsertColumnsString + ' FROM ' + QUOTENAME(@SourceDB)
        + '.[dbo].' + QUOTENAME(@TableName) + ' s' + ' WHERE s.' + @KeyColumn1
        + ' < 50000' + ' AND s.' + @KeyColumn2 + ' < 50000'
        + ' AND NOT EXISTS (SELECT TOP 1 ' + @KeyColumn1 + ' FROM '
        + QUOTENAME(@DestinationDB) + '.[dbo].' + QUOTENAME(@TableName)
        + ' WHERE ' + @KeyColumn1 + ' = s.' + @KeyColumn1
    IF ( NOT @KeyColumn2 IS NULL
       ) 
        SET @SQLString = @SQLString + ' AND ' + @KeyColumn2 + ' = s.'
            + @KeyColumn2
    IF ( NOT @KeyColumn3 IS NULL
       ) 
        SET @SQLString = @SQLString + ' AND ' + @KeyColumn3 + ' = s.'
            + @KeyColumn3
    SET @SQLString = @SQLString + '));'
	
    SELECT  @ExecuteString = CAST(@SQLString AS nvarchar(1000))
    EXEC sp_executesql 
        @ExecuteString
    COMMIT				
END TRY 
BEGIN CATCH
    IF @@TRANCOUNT <> 0 
        BEGIN
            ROLLBACK
        END 
	
    PRINT N'An error occurred performing identity insert in ' + @TableName
        + ' ' + ERROR_MESSAGE() ;
    SELECT  -1
    RETURN 
END CATCH
RETURN
	

GO
GRANT EXECUTE ON  [dbo].[vpspPortalTableDataSynchMultiKey] TO [VCSPortal]
GO
