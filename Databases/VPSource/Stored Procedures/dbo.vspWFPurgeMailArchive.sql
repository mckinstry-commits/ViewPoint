SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/24/2008
-- Description:	Purges all messages from the Mail Archive older than the specified date
-- =============================================
CREATE PROCEDURE [dbo].[vspWFPurgeMailArchive] 
	-- Add the parameters for the stored procedure here
	@purgeDate DateTime = null
WITH EXECUTE AS 'viewpointcs'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @purgeDate >= CURRENT_TIMESTAMP
		TRUNCATE TABLE vMailQueueArchive
	ELSE
		DELETE FROM vMailQueueArchive WHERE (FailureDate < @purgeDate OR FailureDate IS NULL) AND (SentDate < @purgeDate OR SentDate IS NULL)
END

GO
GRANT EXECUTE ON  [dbo].[vspWFPurgeMailArchive] TO [public]
GO
