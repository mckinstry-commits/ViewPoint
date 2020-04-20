SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom J
-- Create date: 2011/11/18
-- Description:	Deletes menu templates and cleans up afterwards
-- =============================================
CREATE PROCEDURE [dbo].[vpspDeleteMenuTemplateAndRelatedRecords]
	@TemplateID int
AS
BEGIN
	DELETE FROM pMenuTemplateLinkRoles  WHERE MenuTemplateID = @TemplateID
	DELETE FROM pMenuTemplateLinks WHERE MenuTemplateID = @TemplateID
	UPDATE pMenuSiteLinks SET MenuTemplateID = NULL WHERE MenuTemplateID = @TemplateID
	DELETE FROM pMenuTemplates WHERE MenuTemplateID = @TemplateID
END

GO
GRANT EXECUTE ON  [dbo].[vpspDeleteMenuTemplateAndRelatedRecords] TO [VCSPortal]
GO
