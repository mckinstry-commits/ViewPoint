SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[vpspSetSiteDefaultPageToWelcomePage]
/************************************************************
* CREATED:     SDE 7/2/2007
* MODIFIED:    
*
* USAGE:
*	Sets the site's Default Page to the PageSiteTemplateID for the
*	Welcome page  
*
* CALLED FROM:
*	ViewpointCS Portal when a new site is created 
*
* INPUT PARAMETERS
* 	SiteID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@siteID int
)
AS
	SET NOCOUNT OFF;

-- PageTemplateID for the Welcome Page Template
DECLARE @WelcomePageTemplateID INT
SET @WelcomePageTemplateID = 444

-- Get the PageSiteTemplateID for this site's Welcome Page
DECLARE @WelcomePageSiteTemplateID INT
SELECT @WelcomePageSiteTemplateID = PageSiteTemplateID FROM pPageSiteTemplates WHERE PageTemplateID = @WelcomePageTemplateID AND SiteID = @siteID

-- Update this site with the Welcome PageTemplateID
UPDATE pSites
	SET PageSiteTemplateID = @WelcomePageSiteTemplateID
	WHERE SiteID = @siteID 


GO
GRANT EXECUTE ON  [dbo].[vpspSetSiteDefaultPageToWelcomePage] TO [VCSPortal]
GO
