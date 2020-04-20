SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE        PROCEDURE [dbo].[vpspLinkControlInsert]
(
	@PageSiteControlID int,
	@LinkOrder int,
	@LinkText varchar(255),
	@URL varchar(255),
	@PopUpHeight int,
	@PopUpWidth int,
	@SiteID int,
	@LinkTypeID int
)
AS
	SET NOCOUNT OFF;

-- Set Null fields
if @PopUpHeight = -1 set @PopUpHeight = Null
if @PopUpWidth = -1 set @PopUpWidth = Null
if @SiteID = -1 set @SiteID = Null
if @LinkTypeID = -1 set @LinkTypeID = Null

INSERT INTO pLinkControl(PageSiteControlID, LinkOrder, LinkText, URL, PopUpHeight, PopUpWidth, SiteID, LinkTypeID) VALUES (@PageSiteControlID, @LinkOrder, @LinkText, @URL, @PopUpHeight, @PopUpWidth, @SiteID, @LinkTypeID);
	
DECLARE @LinkControlID int 
SET @LinkControlID = SCOPE_IDENTITY() 
execute vpspLinkControlGet @PageSiteControlID , @LinkControlID












GO
GRANT EXECUTE ON  [dbo].[vpspLinkControlInsert] TO [VCSPortal]
GO
