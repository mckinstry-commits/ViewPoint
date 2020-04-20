SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 3/5/2008
-- Description:	Add records for notifier email groupings
-- =============================================
CREATE PROCEDURE [dbo].[vspWFNFAddGroupRecord] 
	-- Add the parameters for the stored procedure here
	@JobName VARCHAR(150) = NULL,
	@GroupBy VARCHAR(100) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS (SELECT TOP 1 1 FROM WFNFGrouping WHERE JobName = @JobName AND GroupBy = @GroupBy)
		INSERT INTO WFNFGrouping VALUES (@JobName, @GroupBy)
END
GO
GRANT EXECUTE ON  [dbo].[vspWFNFAddGroupRecord] TO [public]
GO
