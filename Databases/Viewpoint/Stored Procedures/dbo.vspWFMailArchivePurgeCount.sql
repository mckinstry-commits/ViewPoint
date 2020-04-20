SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/24/2008
-- Description:	Gets the number of records in the mail archive table that would be purged by the specified date.
-- =============================================
CREATE PROCEDURE [dbo].[vspWFMailArchivePurgeCount]
	-- Add the parameters for the stored procedure here
	@purgeDate DateTime = NULL,
	@recCount int OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @recCount = COUNT(*) FROM MailQueueArchive WHERE (FailureDate < @purgeDate OR FailureDate IS NULL) AND (SentDate < @purgeDate OR SentDate IS NULL)
	
END

GO
GRANT EXECUTE ON  [dbo].[vspWFMailArchivePurgeCount] TO [public]
GO
