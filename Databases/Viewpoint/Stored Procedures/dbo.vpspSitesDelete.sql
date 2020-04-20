SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  StoredProcedure [dbo].[vpspSitesDelete]    Script Date: 06/14/2011 07:51:46 ******/
CREATE   PROCEDURE [dbo].[vpspSitesDelete]
(
	@Original_SiteID int,
	@Original_Active tinyint,
	@Original_DateCreated datetime,
	@Original_Description varchar(255),
	@Original_HeaderText varchar(50),
	@Original_IdleTimeout int,
	@Original_JCCo tinyint,
	@Original_Job varchar(10),
	@Original_MaxAttachmentSize int,
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_PageSiteTemplateID int,
	@Original_SiteAttachmentID int,
	@Original_UserID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pSites WHERE (SiteID = @Original_SiteID) 
	AND (Active = @Original_Active) 
	AND (DateCreated = @Original_DateCreated) 
	AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) 
	AND (HeaderText = @Original_HeaderText) 
	AND (IdleTimeout = @Original_IdleTimeout OR @Original_IdleTimeout IS NULL AND IdleTimeout IS NULL) 
	AND (JCCo = @Original_JCCo OR @Original_JCCo IS NULL AND JCCo IS NULL) 
	AND (Job = @Original_Job OR @Original_Job IS NULL AND Job IS NULL) 
	AND (MaxAttachmentSize = @Original_MaxAttachmentSize OR @Original_MaxAttachmentSize IS NULL AND MaxAttachmentSize IS NULL) 
	AND (Name = @Original_Name) AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) 
	AND (PageSiteTemplateID = @Original_PageSiteTemplateID) 
	AND (SiteAttachmentID = @Original_SiteAttachmentID OR @Original_SiteAttachmentID IS NULL AND SiteAttachmentID IS NULL) 
	AND (UserID = @Original_UserID)

GO
GRANT EXECUTE ON  [dbo].[vpspSitesDelete] TO [VCSPortal]
GO
