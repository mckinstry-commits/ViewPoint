SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE          PROCEDURE [dbo].[vpspSitesInsert]
/************************************************************
* CREATED:     2/8/06  SDE
* MODIFIED:    
*
* USAGE:
*	Inserts a Site and returns the Inserted Site
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@Name varchar(50),
	@JCCo int,
	@Job varchar(10),
	@DateCreated datetime,
	@UserID int,
	@HeaderText varchar(50),
	@IdleTimeout int,
	@PageSiteTemplateID int,
	@Description varchar(255),
	@Notes varchar(3000),
	@Active tinyint,
	@SiteAttachmentID int,
	@MaxAttachmentSize int
)
AS

DECLARE @SiteID int

	SET NOCOUNT OFF;
-- Set Null fields
if @JCCo = -1 set @JCCo = Null
if @Job = 'Not Set' set @Job = Null
if @PageSiteTemplateID = -1 set @PageSiteTemplateID = Null
if @SiteAttachmentID = -1 set @SiteAttachmentID = Null
if @IdleTimeout = -1 set @IdleTimeout = Null
if @MaxAttachmentSize = -1 set @MaxAttachmentSize = Null

INSERT INTO pSites(Name, JCCo, Job, DateCreated, UserID, HeaderText, IdleTimeout, PageSiteTemplateID, Description, Notes, Active, SiteAttachmentID, MaxAttachmentSize) VALUES (@Name, @JCCo, @Job, @DateCreated, @UserID, @HeaderText, @IdleTimeout, @PageSiteTemplateID, @Description, @Notes, @Active, @SiteAttachmentID, @MaxAttachmentSize);
	
SET @SiteID = SCOPE_IDENTITY()
execute vpspSitesGet @SiteID 
GO
GRANT EXECUTE ON  [dbo].[vpspSitesInsert] TO [VCSPortal]
GO
