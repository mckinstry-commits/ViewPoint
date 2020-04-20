SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPortalDropAuditTrigger]
(
	@TableName as varchar(100)
)
AS

DECLARE @SQLString as varchar(4000),
		@ExecuteString as nvarchar(4000)

--Drop the Audit Trigger if it already exists
set @SQLString = 'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[' + @TableName + 'Audit]'') and OBJECTPROPERTY(id, N''IsTrigger'') = 1)
			drop trigger [dbo].[' + @TableName + 'Audit]'
exec(@SQLString)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalDropAuditTrigger] TO [VCSPortal]
GO
