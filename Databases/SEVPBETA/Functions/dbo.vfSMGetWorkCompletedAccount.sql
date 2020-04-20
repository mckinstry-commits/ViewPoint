SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/8/11
-- Description: Generates the GL Distributions needed for transferring GL to a new account for a work completed line
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetWorkCompletedAccount]
(	
	@SMWorkCompletedID bigint, @CostOrRevenue char(1), @ReturnWIPAccount bit
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT GLCo, 
	CASE @CostOrRevenue 
		WHEN 'C' THEN CASE WHEN @ReturnWIPAccount = 1 THEN CostWIPAccount ELSE CostAccount END
		WHEN 'R' THEN CASE WHEN @ReturnWIPAccount = 1 THEN RevenueWIPAccount ELSE RevenueAccount END
	END GLAccount
	FROM dbo.vSMWorkCompletedDetail
	WHERE SMWorkCompletedID = @SMWorkCompletedID AND IsSession = 0
)

GO
GRANT SELECT ON  [dbo].[vfSMGetWorkCompletedAccount] TO [public]
GO
