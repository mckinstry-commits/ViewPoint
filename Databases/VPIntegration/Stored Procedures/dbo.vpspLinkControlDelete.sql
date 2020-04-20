SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   PROCEDURE [dbo].[vpspLinkControlDelete]
(
	@Original_LinkControlID int,
	@Original_LinkOrder int,
	@Original_LinkText varchar(255),
	@Original_LinkTypeID int,
	@Original_PageSiteControlID int,
	@Original_PopUpHeight int,
	@Original_PopUpWidth int,
	@Original_SiteID int,
	@Original_URL varchar(255)
)
AS
	SET NOCOUNT OFF;

-- Set Null fields
if @Original_PopUpHeight = -1 set @Original_PopUpHeight = Null
if @Original_PopUpWidth = -1 set @Original_PopUpWidth = Null
if @Original_SiteID = -1 set @Original_SiteID = Null
if @Original_LinkTypeID = -1 set @Original_LinkTypeID = Null

DELETE 
FROM pLinkControl 
WHERE (LinkControlID = @Original_LinkControlID) 
AND (LinkOrder = @Original_LinkOrder) 
AND (LinkText = @Original_LinkText OR @Original_LinkText IS NULL AND LinkText IS NULL) 
AND (LinkTypeID = @Original_LinkTypeID OR @Original_LinkTypeID IS NULL AND LinkTypeID IS NULL) 
AND (PageSiteControlID = @Original_PageSiteControlID) 
AND (PopUpHeight = @Original_PopUpHeight OR @Original_PopUpHeight IS NULL AND PopUpHeight IS NULL) 
AND (PopUpWidth = @Original_PopUpWidth OR @Original_PopUpWidth IS NULL AND PopUpWidth IS NULL) 
AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL) 
AND (URL = @Original_URL OR @Original_URL IS NULL AND URL IS NULL)






GO
GRANT EXECUTE ON  [dbo].[vpspLinkControlDelete] TO [VCSPortal]
GO
