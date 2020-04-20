SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 3/5/2008
-- Description:	Retrieves grouping information for notifier jobs
-- =============================================
CREATE PROCEDURE [dbo].[vspWFGetNFGrouping] 
	-- Add the parameters for the stored procedure here
	@JobName VARCHAR(100) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT GroupBy FROM WFNFGrouping WHERE JobName = @JobName
END

GO
GRANT EXECUTE ON  [dbo].[vspWFGetNFGrouping] TO [public]
GO
