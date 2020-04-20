SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/24/2008
-- Description:	Gets the total number of records in the mail archive table
-- =============================================
CREATE PROCEDURE [dbo].[vspWFMailArchiveCount]
	-- Add the parameters for the stored procedure here
	@recCount int OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @recCount = COUNT(*) FROM MailQueueArchive
	
END

GO
GRANT EXECUTE ON  [dbo].[vspWFMailArchiveCount] TO [public]
GO
