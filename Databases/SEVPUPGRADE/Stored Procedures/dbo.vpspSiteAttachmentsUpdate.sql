SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE dbo.vpspSiteAttachmentsUpdate
(
	@SiteID int,
	@Name varchar(50),
	@FileName varchar(50),
	@AttachmentTypeID int,
	@Date datetime,
	@Size int,
	@Description varchar(255),
	@Original_SiteAttachmentID int,
	@Original_AttachmentTypeID int,
	@Original_Date datetime,
	@Original_Description varchar(255),
	@Original_FileName varchar(50),
	@Original_Name varchar(50),
	@Original_SiteID int,
	@Original_Size int,
	@SiteAttachmentID int
)
AS
	SET NOCOUNT OFF;
UPDATE pSiteAttachments SET SiteID = @SiteID, Name = @Name, FileName = @FileName, AttachmentTypeID = @AttachmentTypeID, Date = @Date, Size = @Size, Description = @Description WHERE (SiteAttachmentID = @Original_SiteAttachmentID) AND (AttachmentTypeID = @Original_AttachmentTypeID) AND (Date = @Original_Date OR @Original_Date IS NULL AND Date IS NULL) AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) AND (FileName = @Original_FileName) AND (Name = @Original_Name) AND (SiteID = @Original_SiteID) AND (Size = @Original_Size);
	
execute vpspSiteAttachmentsGet @SiteAttachmentID

GO
GRANT EXECUTE ON  [dbo].[vpspSiteAttachmentsUpdate] TO [VCSPortal]
GO
