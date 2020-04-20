SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.vpspRemovePageTemplateIDReference
(
	@PageTemplateID int
)
AS

SET NOCOUNT OFF;

UPDATE pPageSiteTemplates SET PageTemplateID = NULL WHERE PageTemplateID = @PageTemplateID




GO
GRANT EXECUTE ON  [dbo].[vpspRemovePageTemplateIDReference] TO [VCSPortal]
GO
