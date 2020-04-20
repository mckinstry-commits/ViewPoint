SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPortalTemplateTableDataImport]
(
	@TableName varchar(100),
	@UpdateStatement varchar(1000),
	@KeyColumn varchar(100),
	@InsertStatement varchar(1000)
)
AS

DECLARE @SQLString varchar(1000), 
		@ExecuteString NVARCHAR(1000)

--Update
SET @SQLString = 'Update ' + @TableName + ' SET ' + @UpdateStatement + ' FROM ' + @TableName + ' c INNER JOIN ' +
@TableName + 'INSTALL i ON c.' + @KeyColumn + ' = i.' + @KeyColumn + ' WHERE c.' + @KeyColumn + ' < 50000'
PRINT @SQLString
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

--Insert
SET @SQLString = 'SET IDENTITY_INSERT ' + @TableName + ' ON;'
--PRINT @SQLString
--Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
--exec sp_executesql @ExecuteString

SET @SQLString = @SQLString + ' INSERT INTO ' + @TableName + ' (' + @InsertStatement + ') (SELECT ' + 
@InsertStatement + ' FROM ' + @TableName + 'INSTALL i WHERE i.' + @KeyColumn + ' < 50000 AND i.' +
@KeyColumn + ' NOT IN (SELECT ' + @KeyColumn + ' FROM ' + @TableName + '));'
--PRINT @SQLString
--Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
--exec sp_executesql @ExecuteString

SET @SQLString = @SQLString + ' SET IDENTITY_INSERT ' + @TableName + ' OFF'
PRINT @SQLString
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString

--Delete
SET @SQLString = 'DELETE ' + @TableName + ' WHERE ' + @KeyColumn + ' < 50000 AND ' + @KeyColumn +
' NOT IN (SELECT ' + @KeyColumn + ' FROM ' + @TableName + 'INSTALL)'
PRINT @SQLString
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString



GO
GRANT EXECUTE ON  [dbo].[vpspPortalTemplateTableDataImport] TO [VCSPortal]
GO
