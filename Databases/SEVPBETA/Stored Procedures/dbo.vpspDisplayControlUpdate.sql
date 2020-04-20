SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspDisplayControlUpdate
(
	@PageSiteControlID int,
	@AttachmentID int,
	@DisplayText varchar(8000),
	@SiteID int,
	@Original_PageSiteControlID int,
	@Original_AttachmentID int,
	@Original_DisplayText varchar(8000),
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;

if @AttachmentID = -1 set @AttachmentID = Null
if @Original_AttachmentID = -1 set @Original_AttachmentID = Null
if @SiteID = -1 set @SiteID = Null
if @Original_SiteID = -1 set @Original_SiteID = Null

UPDATE pDisplayControl 
SET PageSiteControlID = @PageSiteControlID, AttachmentID = @AttachmentID, DisplayText = @DisplayText, SiteID = @SiteID 
WHERE (PageSiteControlID = @Original_PageSiteControlID) 
AND (AttachmentID = @Original_AttachmentID OR @Original_AttachmentID IS NULL AND AttachmentID IS NULL) 
AND (DisplayText = @Original_DisplayText OR @Original_DisplayText IS NULL AND DisplayText IS NULL) 
AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL);

execute vpspDisplayControlGet @PageSiteControlID = @PageSiteControlID




GO
GRANT EXECUTE ON  [dbo].[vpspDisplayControlUpdate] TO [VCSPortal]
GO
