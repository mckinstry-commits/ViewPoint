SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 08/25/2008
-- Modified:    09/30/2009; RM - Added AttachmentFormName to track which form the attachment 
--							should be actually attached to
--
-- Description:	This is a validation procedure for the DM After The Fact attachments form.
--
-- Modified: 03/23/09 JonathanP - See 132810. Added AttachmentCompanyColumn output parameters.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMQueryFormNameValidation]	
	@DDFHForm varchar(30), @AttachmentCompanyColumn varchar(30) = null output, @AttachmentFormName varchar(30) = null output, @returnMessage varchar(255) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @returnCode int
	SELECT @returnCode = 0	

    IF not exists (SELECT TOP 1 1 FROM DDQueryableViewsShared WHERE Form = @DDFHForm and AllowAttachments = 'Y')
    BEGIN
		SELECT @returnMessage = isnull(@DDFHForm, '[no form specified]') + ' is not a valid form name.', @returnCode = 1
		GOTO vspExit
    END

	SELECT top 1 @AttachmentCompanyColumn = AttachmentCompanyColumn, 
				 @AttachmentFormName = AttachmentFormName 
	FROM DDQueryableViewsShared 
	WHERE Form = @DDFHForm and AllowAttachments = 'Y'

vspExit:
	return @returnCode

END

GO
GRANT EXECUTE ON  [dbo].[vspDMQueryFormNameValidation] TO [public]
GO
