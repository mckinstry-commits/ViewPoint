SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[vpspCreateNewSiteHelpFileLinks]
/************************************************************
* CREATED:     SDE 3/21/2007
* MODIFIED:    
*
* USAGE:
*   	Creates links for the Directory Browser control that points
*	to the Admin and User help files.  
*
* CALLED FROM:
*	ViewpointCS Portal when a new site is created 
*
* INPUT PARAMETERS
* 	SiteID, PhysicalPath
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@siteID int, @physicalApplicationPath varchar(255)
)
AS
	SET NOCOUNT OFF;

-- Physial path to Admin Help
declare @adminHelpPath VARCHAR(255)
set @adminHelpPath = @physicalApplicationPath + 'Help\Administrators'

-- Physical path to User Help
declare @userHelpPath VARCHAR(255)
set @userHelpPath = @physicalApplicationPath + 'Help\Users'

/*
	Administrator Help
*/

-- PageTemplateID for the Admin Help Page Template
declare @adminHelpPageTemplateID int
SET @adminHelpPageTemplateID = 465

-- Get the PageSiteTemplateID for the page that holds the Admin Help Control
declare @pageSiteTemplateID int
select @pageSiteTemplateID = PageSiteTemplateID from pPageSiteTemplates where PageTemplateID = @adminHelpPageTemplateID and SiteID = @siteID

-- Get the PageSiteControlID for the Admin Help Control
declare @pageSiteControlID int
select @pageSiteControlID = PageSiteControlID from pPageSiteControls where PageSiteTemplateID = @pageSiteTemplateID and SiteID = @siteID

-- Create the links to the Admin help files
insert into pDirectoryBrowser (PageSiteControlID, Directory) values (@pageSiteControlID, @adminHelpPath)

/*
	User Help 
*/

-- PageTemplateID for the User Help Page Template
declare @userHelpPageTemplateID int
set @userHelpPageTemplateID = 466

-- Get the PageSiteTemplateID for the page that holds the User Help Control
select @pageSiteTemplateID = PageSiteTemplateID from pPageSiteTemplates where PageTemplateID = @userHelpPageTemplateID and SiteID = @siteID

-- Get the PageSiteControlID for the User Help Control
select @pageSiteControlID = PageSiteControlID from pPageSiteControls where PageSiteTemplateID = @pageSiteTemplateID and SiteID = @siteID

-- Create the links to the User help files
insert into pDirectoryBrowser (PageSiteControlID, Directory) values (@pageSiteControlID, @userHelpPath)


GO
GRANT EXECUTE ON  [dbo].[vpspCreateNewSiteHelpFileLinks] TO [VCSPortal]
GO
