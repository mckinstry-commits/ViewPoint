
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/28/11
-- Description: Get the default accounting treament based on the SMCo, Work Order, Scope and Line Type.  Optionally the Cost type.
-- Mod:			10/24/2012 TK-18670 Matthew Bradford Added support for LineType 5 and purchase stuff.	
--				10/24/2012 TK-18670 Jacob VH - Modified to use cost type category
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetAccountingTreatment]
(	
	@SMCo bCompany, @WorkOrder int, @Scope int, @CostTypeCategory char(1), @CostType smallint
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
		CROSS APPLY (SELECT ISNULL((SELECT SMCostTypeCategory FROM dbo.vSMCostType WHERE SMCo = @SMCo AND SMCostType = @CostType), @CostTypeCategory) CostTypeCategory) GetCostTypeCategory
		CROSS APPLY
		(
			SELECT TOP 1
				vSMDepartment.Department,
				CASE WHEN vSMWorkOrderScope.IsTrackingWIP = 'Y' AND vSMWorkOrderScope.IsComplete = 'N' THEN 1 ELSE 0 END InWIP,
				GetGLAccounts.*
			FROM
			(
				SELECT GLCo, CostGLAcct, RevenueGLAcct, CostWIPGLAcct, RevenueWIPGLAcct, 4 Ranking 
				FROM dbo.vSMDepartmentOverrides 
				WHERE vSMDepartment.SMCo = vSMDepartmentOverrides.SMCo AND vSMDepartment.Department = vSMDepartmentOverrides.Department AND vSMDepartmentOverrides.CostTypeCategory = GetCostTypeCategory.CostTypeCategory AND vSMDepartmentOverrides.CallType = vSMWorkOrderScope.CallType AND vSMDepartmentOverrides.CostType = @CostType
				UNION
				SELECT GLCo, CostGLAcct, RevenueGLAcct, CostWIPGLAcct, RevenueWIPGLAcct, 3 
				FROM dbo.vSMDepartmentOverrides 
				WHERE vSMDepartment.SMCo = vSMDepartmentOverrides.SMCo AND vSMDepartment.Department = vSMDepartmentOverrides.Department AND vSMDepartmentOverrides.CostTypeCategory = GetCostTypeCategory.CostTypeCategory AND vSMDepartmentOverrides.CostType = @CostType AND vSMDepartmentOverrides.CallType IS NULL
				UNION
				SELECT GLCo, CostGLAcct, RevenueGLAcct, CostWIPGLAcct, RevenueWIPGLAcct, 2 
				FROM dbo.vSMDepartmentOverrides 
				WHERE vSMDepartment.SMCo = vSMDepartmentOverrides.SMCo AND vSMDepartment.Department = vSMDepartmentOverrides.Department AND vSMDepartmentOverrides.CostTypeCategory = GetCostTypeCategory.CostTypeCategory AND vSMDepartmentOverrides.CallType = vSMWorkOrderScope.CallType AND vSMDepartmentOverrides.CostType IS NULL
				UNION
				SELECT 
					vSMDepartment.GLCo,
					CASE CostTypeCategory
						WHEN 'E' THEN vSMDepartment.EquipCostGLAcct
						WHEN 'L' THEN vSMDepartment.LaborCostGLAcct
						WHEN 'M' THEN vSMDepartment.MaterialCostGLAcct
						WHEN 'O' THEN vSMDepartment.OtherCostGLAcct
						WHEN 'S' THEN vSMDepartment.SubcontractCostGLAcct
					END,
					CASE CostTypeCategory
						WHEN 'E' THEN vSMDepartment.EquipRevGLAcct
						WHEN 'L' THEN vSMDepartment.LaborRevGLAcct
						WHEN 'M' THEN vSMDepartment.MaterialRevGLAcct
						WHEN 'O' THEN vSMDepartment.OtherRevGLAcct
						WHEN 'S' THEN vSMDepartment.SubcontractRevGLAcct
					END,
					CASE CostTypeCategory
						WHEN 'E' THEN vSMDepartment.EquipCostWIPGLAcct
						WHEN 'L' THEN vSMDepartment.LaborCostWIPGLAcct
						WHEN 'M' THEN vSMDepartment.MaterialCostWIPGLAcct
						WHEN 'O' THEN vSMDepartment.OtherCostWIPGLAcct
						WHEN 'S' THEN vSMDepartment.SubcontractCostWIPGLAcct
					END,
					CASE CostTypeCategory
						WHEN 'E' THEN vSMDepartment.EquipRevWIPGLAcct
						WHEN 'L' THEN vSMDepartment.LaborRevWIPGLAcct
						WHEN 'M' THEN vSMDepartment.MaterialRevWIPGLAcct
						WHEN 'O' THEN vSMDepartment.OtherRevWIPGLAcct
						WHEN 'S' THEN vSMDepartment.SubcontractRevWIPGLAcct
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
