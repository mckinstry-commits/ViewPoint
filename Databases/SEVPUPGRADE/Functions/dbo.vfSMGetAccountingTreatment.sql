SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/28/11
-- Description: Get the default accounting treament based on the SMCo, Work Order, Scope and Line Type.  Optionally the Cost type.
-- Mod:			10/24/2012 TK-18670 Matthew Bradford Added support for LineType 5 and purchase stuff.	
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetAccountingTreatment]
(	
	@SMCo bCompany, @WorkOrder int, @Scope int, @LineType tinyint, @CostType smallint
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT DeriveGLAccounts.*,
		CASE WHEN DeriveGLAccounts.InWIP = 1 THEN DeriveGLAccounts.CostWIPGLAcct ELSE DeriveGLAccounts.CostGLAcct END CurrentCostGLAcct,
		CASE WHEN DeriveGLAccounts.InWIP = 1 THEN DeriveGLAccounts.RevenueWIPGLAcct ELSE DeriveGLAccounts.RevenueGLAcct END CurrentRevenueGLAcct
	FROM dbo.vSMWorkOrderScope
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkOrder.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkOrderScope.WorkOrder
		INNER JOIN dbo.vSMServiceCenter ON vSMServiceCenter.SMCo = vSMWorkOrder.SMCo AND vSMServiceCenter.ServiceCenter = vSMWorkOrder.ServiceCenter
		LEFT JOIN dbo.vSMDivision ON vSMDivision.SMCo = vSMWorkOrderScope.SMCo AND vSMDivision.ServiceCenter = vSMWorkOrderScope.ServiceCenter AND vSMDivision.Division = vSMWorkOrderScope.Division
		INNER JOIN dbo.vSMDepartment ON vSMDepartment.SMCo = vSMWorkOrderScope.SMCo AND vSMDepartment.Department = ISNULL(vSMDivision.Department, vSMServiceCenter.Department)
		CROSS APPLY
		(
			SELECT TOP 1
				vSMDepartment.Department,
				CASE WHEN vSMWorkOrderScope.IsTrackingWIP = 'Y' AND vSMWorkOrderScope.IsComplete = 'N' THEN 1 ELSE 0 END InWIP,
				GetGLAccounts.*
			FROM
			(
				SELECT GLCo, CostGLAcct, RevenueGLAcct, CostWIPGLAcct, RevenueWIPGLAcct, 4 AS Ranking 
				FROM dbo.vSMDepartmentOverrides 
				WHERE vSMDepartment.SMCo = vSMDepartmentOverrides.SMCo AND vSMDepartment.Department = vSMDepartmentOverrides.Department AND vSMDepartmentOverrides.LineType = @LineType AND vSMDepartmentOverrides.CallType = vSMWorkOrderScope.CallType AND vSMDepartmentOverrides.CostType = @CostType
				UNION
				SELECT GLCo, CostGLAcct, RevenueGLAcct, CostWIPGLAcct, RevenueWIPGLAcct, 3 
				FROM dbo.vSMDepartmentOverrides 
				WHERE vSMDepartment.SMCo = vSMDepartmentOverrides.SMCo AND vSMDepartment.Department = vSMDepartmentOverrides.Department AND vSMDepartmentOverrides.LineType = @LineType AND vSMDepartmentOverrides.CostType = @CostType AND vSMDepartmentOverrides.CallType IS NULL
				UNION
				SELECT GLCo, CostGLAcct, RevenueGLAcct, CostWIPGLAcct, RevenueWIPGLAcct, 2 
				FROM dbo.vSMDepartmentOverrides 
				WHERE vSMDepartment.SMCo = vSMDepartmentOverrides.SMCo AND vSMDepartment.Department = vSMDepartmentOverrides.Department AND vSMDepartmentOverrides.LineType = @LineType AND vSMDepartmentOverrides.CallType = vSMWorkOrderScope.CallType AND vSMDepartmentOverrides.CostType IS NULL
				UNION
				SELECT 
					vSMDepartment.GLCo,
					CASE @LineType 
						WHEN 1 THEN vSMDepartment.EquipCostGLAcct 
						WHEN 2 THEN vSMDepartment.LaborCostGLAcct
						WHEN 3 THEN vSMDepartment.MiscCostGLAcct
						WHEN 4 THEN vSMDepartment.MaterialCostGLAcct
						WHEN 5 THEN vSMDepartment.PurchaseCostGLAcct
					END,
					CASE @LineType 
						WHEN 1 THEN vSMDepartment.EquipRevGLAcct
						WHEN 2 THEN vSMDepartment.LaborRevGLAcct
						WHEN 3 THEN vSMDepartment.MiscRevGLAcct
						WHEN 4 THEN vSMDepartment.MaterialRevGLAcct
						WHEN 5 THEN vSMDepartment.PurchaseRevGLAcct
					END,
					CASE @LineType 
						WHEN 1 THEN vSMDepartment.EquipCostWIPGLAcct
						WHEN 2 THEN vSMDepartment.LaborCostWIPGLAcct
						WHEN 3 THEN vSMDepartment.MiscCostWIPGLAcct
						WHEN 4 THEN vSMDepartment.MaterialCostWIPGLAcct
						WHEN 5 THEN vSMDepartment.PurchaseCostWIPGLAcct
					END,
					CASE @LineType 
						WHEN 1 THEN vSMDepartment.EquipRevWIPGLAcct
						WHEN 2 THEN vSMDepartment.LaborRevWIPGLAcct
						WHEN 3 THEN vSMDepartment.MiscRevWIPGLAcct
						WHEN 4 THEN vSMDepartment.MaterialRevWIPGLAcct
						WHEN 5 THEN vSMDepartment.PurchaseRevWIPGLAcct
					END,
					1 
			) GetGLAccounts
			ORDER BY GetGLAccounts.Ranking DESC
		) DeriveGLAccounts
	WHERE vSMWorkOrderScope.SMCo = @SMCo AND vSMWorkOrderScope.WorkOrder = @WorkOrder AND vSMWorkOrderScope.Scope = @Scope
	
)

GO
GRANT SELECT ON  [dbo].[vfSMGetAccountingTreatment] TO [public]
GO
