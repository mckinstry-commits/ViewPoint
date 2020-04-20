SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
--		Author:	Eric Vaterlaus
-- Create Date: 09/20/11
-- Description:	Access the Call Type Category for a work order using the call type on the first open scope.
-- =============================================
CREATE FUNCTION [dbo].[vfSMWorkOrderCallTypeCategory]
(
	@SMCo bCompany, 
	@WorkOrder int
)
RETURNS TABLE
AS
RETURN
(	
	SELECT TOP 1 
			SMCallTypeCategory.CallTypeCategory,
			SMCallTypeCategory.Description,
			SMCallTypeCategory.Color
	FROM dbo.vSMWorkOrder SMWorkOrder
		INNER JOIN dbo.vSMWorkOrderScope SMWorkOrderScope 
			ON SMWorkOrderScope.SMCo = SMWorkOrder.SMCo
			AND SMWorkOrderScope.WorkOrder = SMWorkOrder.WorkOrder
			AND SMWorkOrderScope.IsComplete = 'N'
		LEFT JOIN dbo.vSMCallType SMCallType
			ON SMCallType.SMCo = SMWorkOrderScope.SMCo
			AND SMCallType.CallType = SMWorkOrderScope.CallType
		LEFT JOIN dbo.vSMCallTypeCategory SMCallTypeCategory
			ON SMCallType.SMCo = SMCallTypeCategory.SMCo
			AND SMCallType.CallTypeCategory = SMCallTypeCategory.CallTypeCategory
	WHERE SMWorkOrder.SMCo = @SMCo AND
		SMWorkOrder.WorkOrder = @WorkOrder
	ORDER BY SMWorkOrderScope.Scope

)
GO
GRANT SELECT ON  [dbo].[vfSMWorkOrderCallTypeCategory] TO [public]
GO
