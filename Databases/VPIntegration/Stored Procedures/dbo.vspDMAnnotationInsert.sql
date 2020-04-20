SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 01/16/2009
-- Description:	See #129917. Saves DM Annotation Data to the vDMAnnotations table. This procedure
--				will update the annotation record if one already exists.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAnnotationInsert]
	@attachmentID int, @annotationData varbinary(max), @returnMessage varchar(512) = '' output		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode int
	SET @returnCode = 0

	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.HQAT WHERE AttachmentID = @attachmentID)
	BEGIN
		set @returnCode = 1
		set @returnMessage = 'Annotation not added. Attachment ID ' + CAST(@attachmentID AS varchar(20)) + ' does not exist.'
		goto vspExit
	END

	-- If there is not annotation data for the given attachment, add it. If annotation
	-- data already exists for the attachment, override the data.
	IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.DMAnnotations WHERE AttachmentID = @attachmentID)
	BEGIN
		INSERT dbo.DMAnnotations (AttachmentID, AnnotationData) 
			VALUES (@attachmentID, @annotationData)
	END
	ELSE
		UPDATE dbo.DMAnnotations 
			SET AnnotationData = @annotationData 
			WHERE AttachmentID = @attachmentID

vspExit:
	
	RETURN @returnCode
	
END

GO
GRANT EXECUTE ON  [dbo].[vspDMAnnotationInsert] TO [public]
GO
