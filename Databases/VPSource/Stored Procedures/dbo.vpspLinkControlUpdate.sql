SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE    PROCEDURE [dbo].[vpspLinkControlUpdate]
(
	@PageSiteControlID int,
	@LinkOrder int,
	@LinkText varchar(255),
	@URL varchar(255),
	@PopUpHeight int,
	@PopUpWidth int,
	@SiteID int,
	@LinkTypeID int,
	@Original_LinkControlID int,
	@Original_LinkOrder int,
	@Original_LinkText varchar(255),
	@Original_LinkTypeID int,
	@Original_PageSiteControlID int,
	@Original_PopUpHeight int,
	@Original_PopUpWidth int,
	@Original_SiteID int,
	@Original_URL varchar(255),
	@LinkControlID int
)
AS
	SET NOCOUNT OFF;

-- Set Null fields
if @PopUpHeight = -1 set @PopUpHeight = Null
if @Original_PopUpHeight = -1 set @Original_PopUpHeight = Null
if @PopUpWidth = -1 set @PopUpWidth = Null
if @Original_PopUpWidth = -1 set @Original_PopUpWidth = Null
if @SiteID = -1 set @SiteID = Null
if @Original_SiteID = -1 set @Original_SiteID = Null
if @LinkTypeID = -1 set @LinkTypeID = Null
if @Original_LinkTypeID = -1 set @Original_LinkTypeID = Null

UPDATE pLinkControl 
SET PageSiteControlID = @PageSiteControlID, LinkOrder = @LinkOrder, LinkText = @LinkText, URL = @URL, PopUpHeight = @PopUpHeight, PopUpWidth = @PopUpWidth, SiteID = @SiteID, LinkTypeID = @LinkTypeID 
WHERE (LinkControlID = @Original_LinkControlID) 
AND (LinkOrder = @Original_LinkOrder) 
AND (LinkText = @Original_LinkText OR @Original_LinkText IS NULL AND LinkText IS NULL) 
AND (LinkTypeID = @Original_LinkTypeID OR @Original_LinkTypeID IS NULL AND LinkTypeID IS NULL) 
AND (PageSiteControlID = @Original_PageSiteControlID) 
AND (PopUpHeight = @Original_PopUpHeight OR @Original_PopUpHeight IS NULL AND PopUpHeight IS NULL) 
AND (PopUpWidth = @Original_PopUpWidth OR @Original_PopUpWidth IS NULL AND PopUpWidth IS NULL) 
AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL) 
AND (URL = @Original_URL OR @Original_URL IS NULL AND URL IS NULL);
	

execute vpspLinkControlGet @PageSiteControlID = @PageSiteControlID, @LinkControlID = @LinkControlID








GO
GRANT EXECUTE ON  [dbo].[vpspLinkControlUpdate] TO [VCSPortal]
GO
