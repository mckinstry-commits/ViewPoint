SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/07/08
-- Description:	Deletes an attachment type in vDMAttachmentTypes or vDMAttachmentTypesCustom
--				depending on the parameters.
--
-- Inputs:
--			
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypesDelete]
	
	@attachmentTypeID int,	
    @custom bYN = 'Y',    				
	@errorMessage varchar(255) = null output
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode int
	SELECT @returnCode = 0

	-- Check if an attachment type ID was specified.
	IF @attachmentTypeID IS NULL
	BEGIN
		SELECT @returnCode = 1
		SELECT @errorMessage = 'Could not delete the attachment type. You must specify an Attachment Type ID.'
		GOTO vspExit
	END

	-- Delete a standard type if @custom = 'N'
    IF UPPER(@custom) = 'N'
    BEGIN					
		DECLARE @userName varchar(128)
		SELECT @userName = SUSER_SNAME()
        
		-- Only allowed to delete standard types if the login is viewpointcs.
		IF LOWER(@userName) <> 'viewpointcs'
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Not allowed to delete a standard attachment type logged in as ' + @userName
			GOTO vspExit
		END
		
		-- This is an extra check. Make sure the specified attachment type ID is not greater than 50000.
		IF @attachmentTypeID >= 50000
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not delete standard attachment type. Standard Attachment Types must have an ID less than 50000.'
			GOTO vspExit
		END
		
		-- Delete a standard attachment type in the standard attachment types table.		
		DELETE vDMAttachmentTypes WHERE AttachmentTypeID = @attachmentTypeID
			
		-- Check to make sure the standard attachment type was deleted.
		IF @@ROWCOUNT <> 1
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not delete standard attachment type with ID = ' + CONVERT(VARCHAR, @attachmentTypeID)
			GOTO vspExit
		END	
    END    
    
    -- Delete a custom type
    ELSE
    BEGIN															
		-- Delete the custom type.
		DELETE vDMAttachmentTypesCustom 			
			WHERE AttachmentTypeID = @attachmentTypeID	
			
		-- Check to make sure the custom attachment type was deleted.
		IF @@ROWCOUNT <> 1
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not delete custom attachment type with ID = ' + CONVERT(VARCHAR, @attachmentTypeID)
			GOTO vspExit
		END														
    END	
END

vspExit:
	return @returnCode
GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypesDelete] TO [public]
GO
