SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspGetPortidocAttachments]
@DocumentId varchar(50),
@CompanyNumber integer
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS AttachmentID,
			da.FullName as OrigFileName,
			null as Description,
			CAST(da.AttachmentId AS VARCHAR(45))as DocName,
			null as AddedBy,
			DBUpdatedDate as AddDate,
			'N' as DocAttchYN,
			@CompanyNumber as HQCo,
			null as Formname,
			null as KeyField,
			null as TableName,
			AttachmentId as UniqueAttchID,
			'A' as CurrentState,
			null as AttachmentTypeID,
			null as Type
	FROM Document.DocumentAttachment as da
	WHERE DocumentId = CAST(@DocumentId as uniqueidentifier);
END
GO
GRANT EXECUTE ON  [dbo].[vspGetPortidocAttachments] TO [public]
GO
