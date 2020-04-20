SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/3/12
-- Description: Returns the gl accounts for a given work completed record
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetWorkCompletedGL]
(	
	@SMWorkCompletedID bigint
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Accounts.*
	FROM dbo.SMWorkCompletedDetail
		INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompletedDetail.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompletedDetail.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompletedDetail.Scope = SMWorkOrderScope.Scope
		CROSS APPLY (
			SELECT 0 InWIP, SMWorkCompletedDetail.GLCo, SMWorkCompletedDetail.CostAccount CurrentCostAccount, SMWorkCompletedDetail.RevenueAccount CurrentRevenueAccount, SMWorkCompletedDetail.CostWIPAccount TransferToCostAccount, SMWorkCompletedDetail.RevenueWIPAccount TransferToRevenueAccount
			WHERE CASE WHEN SMWorkOrderScope.IsTrackingWIP = 'Y' AND SMWorkOrderScope.IsComplete = 'N' THEN 1 ELSE 0 END = 0
			UNION ALL
			SELECT 1 InWIP, SMWorkCompletedDetail.GLCo, SMWorkCompletedDetail.CostWIPAccount, SMWorkCompletedDetail.RevenueWIPAccount, SMWorkCompletedDetail.CostAccount, SMWorkCompletedDetail.RevenueAccount
			WHERE CASE WHEN SMWorkOrderScope.IsTrackingWIP = 'Y' AND SMWorkOrderScope.IsComplete = 'N' THEN 1 ELSE 0 END = 1) Accounts
	WHERE SMWorkCompletedDetail.SMWorkCompletedID = @SMWorkCompletedID
)

GO
GRANT SELECT ON  [dbo].[vfSMGetWorkCompletedGL] TO [public]
GO
