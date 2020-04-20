SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPortalTemplateTableDataInsert]
/********************************
* Created: George Clingerman
* Modified: Tim Stevens - 01/20/2009
*			Jeremiah Barkley 11/25/09 - Modified query in client modified case 2 - the query was previously never doing anything
*
* Used by VPUpdate to prepare tables for importing metadata for VP Connects
*
* Input: 
*	@destdb - Database where will be configuring VP Connects product
*
* Output:
*	@msg		
*
* Return code:
* @rcode - anything except 0 indicates an error
*
*********************************/
(
	@SourceDB varchar(100),
	@TableName varchar(100),
	@InsertStatement varchar(1000),
	@KeyColumn varchar(100),
	@ClientModified int = 0,
	@UniqueIndexColumn varchar(100) = NULL
)
AS

DECLARE @SQLString varchar(1000), 
		@ExecuteString NVARCHAR(1000)

--Insert data from source database into customers database retaining identity column values 
	IF @ClientModified = 0 -- Don't need to worry about checking if table has been modified by the customer
		BEGIN
			SET @SQLString = 'SET IDENTITY_INSERT ' + @TableName + ' ON;'

			SET @SQLString = @SQLString + ' INSERT INTO ' + @TableName + ' (' + @InsertStatement + ') (SELECT ' + 
			@InsertStatement + ' FROM ' + @SourceDB + @TableName + ' i WHERE i.' + @KeyColumn + ' < 50000 AND i.' +
			@KeyColumn + ' NOT IN (SELECT ' + @KeyColumn + ' FROM ' + @TableName + '));'

			SET @SQLString = @SQLString + ' SET IDENTITY_INSERT ' + @TableName + ' OFF'
			Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
			BEGIN TRAN
			exec sp_executesql @ExecuteString
		END
	ELSE
	IF @ClientModified = 1
		BEGIN -- Do need to check if the table has been modified by the customer
			SET @SQLString = 'SET IDENTITY_INSERT ' + @TableName + ' ON;'

			SET @SQLString = @SQLString + ' INSERT INTO ' + @TableName + ' (' + @InsertStatement + ') SELECT ' + 
			@InsertStatement + ' FROM ' + @SourceDB + @TableName + ' i WHERE i.' + @KeyColumn + ' < 50000 AND i.' +
			@KeyColumn + ' NOT IN (SELECT ' + @KeyColumn + ' FROM ' + @TableName + ' WHERE ' + @TableName + '.ClientModified = 1);'

			SET @SQLString = @SQLString + ' SET IDENTITY_INSERT ' + @TableName + ' OFF'
			Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
			BEGIN TRAN
			exec sp_executesql @ExecuteString
		END
	ELSE
	IF @ClientModified = 2
		BEGIN -- Need to do a NOT EXISTS because returning more than one column
			SET @SQLString = 'SET IDENTITY_INSERT ' + @TableName + ' ON;'

			SET @SQLString = @SQLString + ' INSERT INTO ' + @TableName + ' (' + @InsertStatement + ') (SELECT ' + 
			@InsertStatement + ' FROM ' + @SourceDB + @TableName + ' i WHERE NOT EXISTS (SELECT ' + @KeyColumn + ',' +
			@UniqueIndexColumn + ' FROM ' + @TableName + ' WHERE ' + @KeyColumn + ' = i.' + @KeyColumn +
			' AND ' + @UniqueIndexColumn + ' = i.' + @UniqueIndexColumn + ') AND i.' + @KeyColumn + ' < 50000 );'

			SET @SQLString = @SQLString + ' SET IDENTITY_INSERT ' + @TableName + ' OFF'
			Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
			BEGIN TRAN
			exec sp_executesql @ExecuteString
		END
			
IF @@ERROR <> 0
	BEGIN
		ROLLBACK
			PRINT N'An error occurred performing identity insert in ' + @TableName;
			SELECT -1
			RETURN 
		END
ELSE
	BEGIN
		COMMIT
		RETURN
	END

GO
GRANT EXECUTE ON  [dbo].[vpspPortalTemplateTableDataInsert] TO [VCSPortal]
GO
