SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/03/08
-- Description:	Inserts an attachment type in vDMAttachmentTypes or vDMAttachmentTypesCustom
--				depending on the parameters.
--
-- Inputs:
--			
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypesInsert]
	
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

	-- Add a standard type if @custom = 'N'
    IF UPPER(@custom) = 'N'
    BEGIN  
		IF @textID IS NULL
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not add new standard attachment type. You must specify a TextID for the type.'
			GOTO vspExit
		END		
    
    	DECLARE @userName varchar(128)
		SELECT @userName = SUSER_SNAME()
    
		-- Only allowed to add standard types if the login is viewpointcs.
		IF LOWER(@userName) <> 'viewpointcs'
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Not allowed to add a standard attachment type logged in as ' + @userName
			GOTO vspExit
		END
		
		-- Insert a new attachment type into the standard attachment type table.		
		INSERT INTO vDMAttachmentTypes (TextID, [Description])
			VALUES (@textID, @description)		
    END    
    
    -- Add a custom type
    ELSE
    BEGIN		
		DECLARE @newAttachmentTypeID int
						
		-- Make sure a type name was specified.
		IF ISNULL(@attachmentTypeName, '') = ''
		BEGIN
			SELECT @returnCode = 1
			SELECT @errorMessage = 'Could not add new custom attachment type. You must specify a name for the type.'
			goto vspExit
		END
		
		-- Get the next AttachmentTypeID number.
		SELECT @newAttachmentTypeID = ISNULL(MAX(AttachmentTypeID), 50000) + 1 
			FROM vDMAttachmentTypesCustom 
			WHERE AttachmentTypeID > 50000	
			
		-- Insert the record into the custom attachment types table.
		INSERT INTO vDMAttachmentTypesCustom (AttachmentTypeID, Name, [Description])
			VALUES (@newAttachmentTypeID, @attachmentTypeName, @description)		
    END	
END

vspExit:
	return @returnCode
GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypesInsert] TO [public]
GO
