SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 01/16/2009
-- Description:	See #129917. Deletes a DM Annotation from the vDMAnnotations table.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAnnotationDelete]
	@attachmentID int, @returnMessage varchar(512) = '' output		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode int
	SET @returnCode = 0

	DELETE FROM dbo.DMAnnotations WHERE AttachmentID = @attachmentID
	
	RETURN @returnCode
	
END

GO
GRANT EXECUTE ON  [dbo].[vspDMAnnotationDelete] TO [public]
GO
