SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 3/5/2008
-- Description:	Removes records for notifier email groupings
-- =============================================
CREATE PROCEDURE [dbo].[vspWFNFRemoveGroupRecord] 
	-- Add the parameters for the stored procedure here
	@JobName VARCHAR(150) = NULL,
	@GroupBy VARCHAR(100) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF EXISTS (SELECT TOP 1 1 FROM WFNFGrouping WHERE JobName = @JobName AND GroupBy = @GroupBy)
	DELETE FROM WFNFGrouping WHERE JobName = @JobName and GroupBy = @GroupBy
END

GO
GRANT EXECUTE ON  [dbo].[vspWFNFRemoveGroupRecord] TO [public]
GO
