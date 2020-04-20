SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspPortalTemplateTableDataUpdate]
(
	@TableName varchar(100),
	@UpdateStatement varchar(1000),
	@KeyColumn varchar(100)
)
AS

DECLARE @SQLString varchar(1000), 
		@ExecuteString NVARCHAR(1000)

--Update
SET @SQLString = 'Update ' + @TableName + ' SET ' + @UpdateStatement + ' FROM ' + @TableName + ' c INNER JOIN ' +
@TableName + 'INSTALL i ON c.' + @KeyColumn + ' = i.' + @KeyColumn + ' WHERE c.' + @KeyColumn + ' < 50000 AND c.ClientModified = 0'
PRINT @SQLString
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString





GO
GRANT EXECUTE ON  [dbo].[vpspPortalTemplateTableDataUpdate] TO [VCSPortal]
GO
