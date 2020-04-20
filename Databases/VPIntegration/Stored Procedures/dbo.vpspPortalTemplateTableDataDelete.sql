SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspPortalTemplateTableDataDelete]
(
	@TableName varchar(100),
	@KeyColumn varchar(100)
)
AS

DECLARE @SQLString varchar(1000), 
		@ExecuteString NVARCHAR(1000)

--Delete
SET @SQLString = 'DELETE ' + @TableName + ' WHERE ClientModified = 0 AND ' + @KeyColumn + ' < 50000 AND ' + @KeyColumn +
' NOT IN (SELECT ' + @KeyColumn + ' FROM ' + @TableName + 'INSTALL)'
PRINT @SQLString
Select @ExecuteString = CAST(@SQLString AS NVarchar(1000))
exec sp_executesql @ExecuteString





GO
GRANT EXECUTE ON  [dbo].[vpspPortalTemplateTableDataDelete] TO [VCSPortal]
GO
