SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspDisplayControlInsert
(
	@PageSiteControlID int,
	@AttachmentID int,
	@DisplayText varchar(8000),
	@SiteID int
)
AS
	SET NOCOUNT OFF;

if @AttachmentID = -1 set @AttachmentID = Null
if @SiteID = -1 set @SiteID = Null

INSERT INTO pDisplayControl(PageSiteControlID, AttachmentID, DisplayText, SiteID) 
VALUES (@PageSiteControlID, @AttachmentID, @DisplayText, @SiteID);

execute vpspDisplayControlGet @PageSiteControlID = @PageSiteControlID



GO
GRANT EXECUTE ON  [dbo].[vpspDisplayControlInsert] TO [VCSPortal]
GO
