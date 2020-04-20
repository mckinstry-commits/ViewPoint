SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/15/08	
-- Description:	Get's the next attachment type ID from the custom attachment type table.
--
-- Modified: 10/24/2008 - #130736. Added isnull(MAX(AttachmentTypeID + 1), 1) in place of  MAX(AttachmentTypeID + 1)
-- =============================================
CREATE PROCEDURE [dbo].[vspDMGetNextAttachmentTypeIDCustom]
	
	(@nextAttachmentTypeID int output, @errorMessage varchar(255) = '' output)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode INT
	SELECT @returnCode = 0
    
    SELECT @nextAttachmentTypeID = isnull(MAX(AttachmentTypeID + 1), 1) FROM DMAttachmentTypesShared
    
    IF @nextAttachmentTypeID < 50000
    BEGIN
		SELECT @nextAttachmentTypeID = 50001
    END
    

vspExit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDMGetNextAttachmentTypeIDCustom] TO [public]
GO
