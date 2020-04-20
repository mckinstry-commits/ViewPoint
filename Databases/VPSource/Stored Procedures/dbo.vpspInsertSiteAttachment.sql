SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE      PROCEDURE [dbo].[vpspInsertSiteAttachment]
/************************************************************
* CREATED:     SDE 7/5/2005
* MODIFIED:    
*
* USAGE:
*   Inserts a site attachment binary data to the Portal
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
* 	SiteAttachmentID, Type, Data
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@SiteAttachmentID int,
	@Type varchar(50),
	@Data image
)
AS
	SET NOCOUNT OFF;
--Insert Binary into pSiteAttachmentBinaries
insert into pSiteAttachmentBinaries(SiteAttachmentID, Type, Data) values (@SiteAttachmentID, @Type, @Data);



GO
GRANT EXECUTE ON  [dbo].[vpspInsertSiteAttachment] TO [VCSPortal]
GO
