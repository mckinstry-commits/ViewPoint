SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


(
	@MenuTemplateID int
)
AS

UPDATE pMenuSiteLinks SET MenuTemplateID = NULL WHERE MenuTemplateID = @MenuTemplateID



GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinksRemoveMenuTemplateReference] TO [VCSPortal]
GO