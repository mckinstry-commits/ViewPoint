SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE dbo.vpspPortalExecuteLookup
(
	@lookup as varchar(4000)	
)
AS

SET NOCOUNT ON;

DECLARE @ExecuteString as nvarchar(4000)

Select @ExecuteString = CAST(@lookup AS NVarchar(4000))
exec sp_executesql @ExecuteString



GO
GRANT EXECUTE ON  [dbo].[vpspPortalExecuteLookup] TO [VCSPortal]
GO
