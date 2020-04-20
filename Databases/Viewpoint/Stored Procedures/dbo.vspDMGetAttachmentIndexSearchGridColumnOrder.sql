SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, vspDMGetAttachmentIndexSearchGridColumnOrder
-- Create date: 10/10/10
-- Modified: 10/16/10 Added Union
-- Description:	Returns the column order for the attachment index search grid by user.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMGetAttachmentIndexSearchGridColumnOrder]

(@username bVPUserName)

AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if EXISTS (SELECT TOP 1 * from DMAttachmentGridColumnOrder WHERE VPUserName = @username)
BEGIN
SELECT ColumnName FROM(
			SELECT ColumnName, ColumnOrder
			From DMAttachmentGridColumnOrder 
			WHERE VPUserName = @username
			UNION ALL
			SELECT HQAIColumnName, 10000
			FROM DMAttachmentGridOptions
			WHERE HQAIColumnName not in (SELECT ColumnName FROM DMAttachmentGridColumnOrder Where VPUserName = @username)
			AND UserName = @username ) AttachmentColumns
			 
			 ORDER BY ColumnOrder
END	

	
END

GO
GRANT EXECUTE ON  [dbo].[vspDMGetAttachmentIndexSearchGridColumnOrder] TO [public]
GO
