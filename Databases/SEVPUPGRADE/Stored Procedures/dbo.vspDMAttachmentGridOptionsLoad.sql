SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, DMAttachmentGridOptionsLoad
-- Create date: 11/30/09
-- Description:	Returns values used to populate the AttachmentGridOptions checkListBox.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentGridOptionsLoad]

(@username bVPUserName)

AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



	SELECT COLUMN_NAME, HQAIColumnName
	from INFORMATION_SCHEMA.COLUMNS i left Join (Select HQAIColumnName from vDMAttachmentGridOptions
	Where UserName = @username) d
	on i.COLUMN_NAME = d. HQAIColumnName 
	Where TABLE_NAME = 'bHQAI' and COLUMN_NAME <> 'AttachmentID' AND COLUMN_NAME <> 'UniqueAttchID'
		Order by COLUMN_NAME
	
END

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentGridOptionsLoad] TO [public]
GO
