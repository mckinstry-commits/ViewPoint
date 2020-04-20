SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/07/08
-- Description:	Updates an attachment type in vDMAttachmentTypes or vDMAttachmentTypesCustom
--				depending on the parameters.
--
-- Inputs:
--			
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypesUpdate]
	
	@attachmentTypeID int,	
    @custom bYN = 'Y',    
	@attachmentTypeName varchar(50) = null, 	
	@textID int = null, 
	@description varchar(255) = null,	 	
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
		SELECT @errorMessage = 'Could not update the attachment type. You must specify an Attachment Type ID.'
		GOTO vspExit
	END

	-- Update a standard type if @custom = 'N'
    IF UPPER(@custom) = 'N'
    BEGIN
		-- Since we are updating a standard type, a TextID should have been given. Check that one was.
		IF @textID IS NULL
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not add update standard attachment type. You must specify a TextID for the type.'
			GOTO vspExit
		END		
			
		DECLARE @userName varchar(128)
		SELECT @userName = SUSER_SNAME()
        
		-- Only allowed to update standard types if the login is viewpointcs.
		IF LOWER(@userName) <> 'viewpointcs'
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Not allowed to add a standard attachment type logged in as ' + @userName
			GOTO vspExit
		END
		
		-- This is an extra check. Make sure the specified attachment type ID is not greater than 50000.
		IF @attachmentTypeID >= 50000
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not update standard attachment type. Standard Attachment Types must have an ID less than 50000.'
			GOTO vspExit
		END
		
		-- Update a standard attachment type in the standard attachment types table.		
		UPDATE vDMAttachmentTypes 
			SET TextID = @textID, [Description] = @description
			WHERE AttachmentTypeID = @attachmentTypeID
			
		-- Check to make sure the standard attachment type was updated.
		IF @@ROWCOUNT <> 1
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not update standard attachment type with ID = ' + CONVERT(VARCHAR, @attachmentTypeID)
			GOTO vspExit
		END	
    END    
    
    -- Update a custom type
    ELSE
    BEGIN						
		-- Make sure a type name was specified.				
		IF ISNULL(@attachmentTypeName, '') = ''
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not update custom attachment type. You must specify a name for the type.'
			GOTO vspExit
		END						
			
		-- Used for the @@ROWCOUNT check below.
		SELECT TOP 1 1 FROM vDMAttachmentTypesCustom WHERE AttachmentTypeID = @attachmentTypeID		
		
		-- If @@ROWCOUNT is 0, then the given attachment type ID does not exist yet in the custom table, so it 
		-- has not been overridden yet.	In this case, we'll add a new record into vDMAttachmentTypesCustom.	
		IF @@ROWCOUNT = 0
		BEGIN
			-- This is an extra check. Make sure the specified attachment type ID is not greater than 50000 since this is an override.
			IF @attachmentTypeID >= 50000
			BEGIN
				SELECT @returnCode = 1
				SELECT @errorMessage = 'Could not override standard attachment type. Standard Attachment Types must have an ID less than 50000.'
				GOTO vspExit
			END
		
			-- Insert the custom type into the custom attachment types table (it is will now override the standard type).
			INSERT INTO vDMAttachmentTypesCustom (AttachmentTypeID, Name, [Description])
				VALUES (@attachmentTypeID, @attachmentTypeName, @description)	
		END
		
		-- The given standard attachment type is already overriden in the custom table so update that record.
		ELSE
		BEGIN
			-- Update the custom type.
			UPDATE vDMAttachmentTypesCustom 
				SET Name = @attachmentTypeName, [Description] = @description
				WHERE AttachmentTypeID = @attachmentTypeID	
				
			-- Check to make sure the custom attachment type was updated.
			IF @@ROWCOUNT <> 1
			BEGIN
				SELECT @returnCode = 1
				SELECT @errorMessage = 'Could not update custom attachment type with ID = ' + CONVERT(VARCHAR, @attachmentTypeID)
				GOTO vspExit
			END	
		END												
    END	
END

vspExit:
	return @returnCode
GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypesUpdate] TO [public]
GO
