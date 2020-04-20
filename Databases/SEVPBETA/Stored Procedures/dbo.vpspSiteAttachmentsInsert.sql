SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE [dbo].[vpspSiteAttachmentsInsert]
(
	@SiteID int,
	@Name varchar(50),
	@FileName varchar(50),
	@AttachmentTypeID int,
	@Date datetime,
	@Size int,
	@Description varchar(255)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pSiteAttachments(SiteID, Name, FileName, AttachmentTypeID, Date, Size, Description) VALUES (@SiteID, @Name, @FileName, @AttachmentTypeID, @Date, @Size, @Description);
	
declare @SiteAttachmentID int
set @SiteAttachmentID = SCOPE_IDENTITY()
execute vpspSiteAttachmentsGet @SiteAttachmentID 


GO
GRANT EXECUTE ON  [dbo].[vpspSiteAttachmentsInsert] TO [VCSPortal]
GO
