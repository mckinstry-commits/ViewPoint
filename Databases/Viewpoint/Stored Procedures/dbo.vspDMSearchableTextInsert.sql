SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMSearchableTextInsert]
/*******************************

	Created by: CC 03/05/2010 Issue #130945 
	Updated by: 

*******************************/
@attachmentID	INT,
@searchText		NVARCHAR(MAX),
@source			NVARCHAR(15)
AS
BEGIN
	SET NOCOUNT ON;
	
	INSERT INTO dbo.vDMSearchableText (AttachmentID, SearchText, [Source]) VALUES (@attachmentID, @searchText, @source);
END
GO
GRANT EXECUTE ON  [dbo].[vspDMSearchableTextInsert] TO [public]
GO
