SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE       PROCEDURE [dbo].[vpspSitesUpdate]
/************************************************************
* CREATED:     2/8/06  SDE
* MODIFIED:    
*
* USAGE:
*	Updates a Site and returns the Updated Site
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
	@MaxAttachmentSize int,
	@Original_SiteID int,
	@Original_Active tinyint,
	@Original_DateCreated datetime,
	@Original_Description varchar(255),
	@Original_HeaderText varchar(50),
	@Original_IdleTimeout int,
	@Original_JCCo int,
	@Original_Job varchar(10),
	@Original_MaxAttachmentSize int,
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_PageSiteTemplateID int,
	@Original_SiteAttachmentID int,
	@Original_UserID int,
	@SiteID int
)
AS
	SET NOCOUNT OFF;

-- Set Null fields
if @JCCo = -1 set @JCCo = Null
if @Original_JCCo = -1 set @Original_JCCo = Null
if @Job = 'Not Set' set @Job = Null
if @Original_Job = 'Not Set' set @Original_Job = Null
if @PageSiteTemplateID = -1 set @PageSiteTemplateID = Null
if @Original_PageSiteTemplateID = -1 set @Original_PageSiteTemplateID = Null
if @SiteAttachmentID = -1 set @SiteAttachmentID = Null
if @Original_SiteAttachmentID = -1 set @Original_SiteAttachmentID = Null
if @IdleTimeout = -1 set @IdleTimeout = Null
if @Original_IdleTimeout = -1 set @Original_IdleTimeout = Null
if @MaxAttachmentSize = -1 set @MaxAttachmentSize = Null
if @Original_MaxAttachmentSize = -1 set @Original_MaxAttachmentSize = Null

UPDATE pSites SET Name = @Name, JCCo = @JCCo, Job = @Job, DateCreated = @DateCreated, UserID = @UserID, HeaderText = @HeaderText, IdleTimeout = @IdleTimeout, PageSiteTemplateID = @PageSiteTemplateID, Description = @Description, Notes = @Notes, Active = @Active, SiteAttachmentID = @SiteAttachmentID, MaxAttachmentSize = @MaxAttachmentSize  
	WHERE (SiteID = @Original_SiteID) 
	AND (Active = @Original_Active) 
	AND (DateCreated = @Original_DateCreated) 
	AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) 
	AND (HeaderText = @Original_HeaderText) 
	AND (IdleTimeout = @Original_IdleTimeout OR @Original_IdleTimeout IS NULL AND IdleTimeout IS NULL) 
	AND (JCCo = @Original_JCCo OR @Original_JCCo IS NULL AND JCCo IS NULL) 
	AND (Job = @Original_Job OR @Original_Job IS NULL AND Job IS NULL) 
	AND (MaxAttachmentSize = @Original_MaxAttachmentSize OR @Original_MaxAttachmentSize IS NULL AND MaxAttachmentSize IS NULL) 
	AND (Name = @Original_Name) 
	AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) 
	AND (PageSiteTemplateID = @Original_PageSiteTemplateID OR @Original_PageSiteTemplateID IS NULL 
	AND PageSiteTemplateID IS NULL) 
	AND (SiteAttachmentID = @Original_SiteAttachmentID OR @Original_SiteAttachmentID IS NULL 
	AND SiteAttachmentID IS NULL) 
	AND (UserID = @Original_UserID);
	
execute vpspSitesGet @SiteID

GO
GRANT EXECUTE ON  [dbo].[vpspSitesUpdate] TO [VCSPortal]
GO
