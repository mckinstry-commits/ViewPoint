SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP	
-- Create date: 03/30/09
-- Description:	127603 - This procedure will get all the attachments that are queued up for deletion.	
-- =============================================
CREATE PROCEDURE [dbo].[vspDMGetAttachmentDeletionQueue]	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

	-- Get all the records in the attachment deletion queue.
	select * from vDMAttachmentDeletionQueue    
    
END

GO
GRANT EXECUTE ON  [dbo].[vspDMGetAttachmentDeletionQueue] TO [public]
GO
