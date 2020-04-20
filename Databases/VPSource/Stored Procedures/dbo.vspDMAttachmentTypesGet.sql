SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/21/08	
-- Description:	Returns a result set of all the attachment types.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypesGet]
	
	(@errorMessage varchar(255) = '' output)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode INT
	SELECT @returnCode = 0       
    	            
	SELECT * FROM DMAttachmentTypesShared

vspExit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypesGet] TO [public]
GO
