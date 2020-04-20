SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/8/11
-- Description:	Returns WorkCompletedIDs for Miscellaneous records that need to be processed.
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetWorkCompletedMiscellaneousToBeProcessed]
(	
	@SMCo bCompany, @Mth bMonth, @ServiceCenter varchar(10), @Division varchar(10), @MinDate bDate, @MaxDate bDate
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT SMWorkCompletedAllCurrent.SMWorkCompletedID, ChangesMade
	FROM dbo.SMWorkCompletedAllCurrent
		INNER JOIN dbo.SMCO ON SMWorkCompletedAllCurrent.SMCo = SMCO.SMCo
		INNER JOIN dbo.SMWorkOrder ON SMWorkCompletedAllCurrent.SMCo = SMWorkOrder.SMCo AND SMWorkCompletedAllCurrent.WorkOrder = SMWorkOrder.WorkOrder
		INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompletedAllCurrent.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompletedAllCurrent.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompletedAllCurrent.Scope = SMWorkOrderScope.Scope
		CROSS APPLY dbo.vfSMGetWorkCompletedGL(SMWorkCompletedAllCurrent.SMWorkCompletedID)
		LEFT JOIN dbo.vSMWorkCompletedGL ON SMWorkCompletedAllCurrent.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
		LEFT JOIN dbo.vSMGLDetailTransaction AS SMGLCostDT ON vSMWorkCompletedGL.CostGLDetailTransactionID = SMGLCostDT.SMGLDetailTransactionID
		LEFT JOIN dbo.vSMGLDetailTransaction AS SMGLRevenueDT ON vSMWorkCompletedGL.RevenueGLDetailTransactionID = SMGLRevenueDT.SMGLDetailTransactionID
		LEFT JOIN dbo.SMMiscellaneousBatch ON SMWorkCompletedAllCurrent.SMWorkCompletedID = SMMiscellaneousBatch.SMWorkCompletedID
		LEFT JOIN dbo.JCCD ON SMWorkCompletedAllCurrent.JCCo = JCCD.JCCo AND SMWorkCompletedAllCurrent.JCCostTrans = JCCD.CostTrans AND SMWorkCompletedAllCurrent.JCMth = JCCD.Mth
		CROSS APPLY (SELECT
			~(dbo.vfIsEqual(SMGLCostDT.GLCo, SMWorkCompletedAllCurrent.GLCo)
					& ((CAST(CASE WHEN (JCCD.CostType = SMWorkCompletedAllCurrent.JCCostType) OR JCCD.CostType IS NULL THEN 1 ELSE 0 END AS Bit)
						& dbo.vfIsEqual(JCCD.Phase, SMWorkOrderScope.Phase)
						& dbo.vfIsEqual(SMGLRevenueDT.GLAccount, CurrentRevenueAccount)
						& dbo.vfIsEqual(SMGLRevenueDT.Amount, ISNULL(-SMWorkCompletedAllCurrent.PriceTotal, 0))
						& dbo.vfIsEqual(SMGLRevenueDT.GLCo, SMWorkCompletedAllCurrent.GLCo))
						| (CAST(CASE WHEN SMWorkOrderScope.Job IS NULL THEN 1 ELSE 0 END AS BIT)))
					& dbo.vfIsEqual(SMGLCostDT.GLAccount, CurrentCostAccount)
					& dbo.vfIsEqual(SMGLCostDT.Amount, ISNULL(SMWorkCompletedAllCurrent.ActualCost, 0))
					& dbo.vfIsEqual(SMGLCostDT.ActDate, SMWorkCompletedAllCurrent.[Date])) | SMWorkCompletedAllCurrent.IsDeleted AS ChangesMade,
			CASE WHEN SMMiscellaneousBatch.SMMiscBatchID IS NOT NULL THEN 1 ELSE 0 END IsInABatch,
			dbo.vfIsEqual(SMMiscellaneousBatch.Mth, SMWorkCompletedAllCurrent.MonthToPostCost) AS IsInCorrectBatch) WorkCompletedEvaluation
	WHERE SMWorkCompletedAllCurrent.[Type] = 3 AND SMWorkCompletedAllCurrent.APTLKeyID IS NULL --Find all miscellaneous work completed records that weren't created by AP
		AND ((ChangesMade = 1 AND IsInCorrectBatch = 0) OR (ChangesMade = 0 AND IsInABatch = 1))
		AND SMWorkCompletedAllCurrent.SMCo = @SMCo --Filter by the required SMCo
		AND (@ServiceCenter IS NULL OR SMWorkOrder.ServiceCenter = @ServiceCenter) --Filter by the optional Service Center
		AND (@Division IS NULL OR SMWorkOrderScope.Division = @Division) --Filter by the optional Division
		AND (@Mth IS NULL OR SMWorkCompletedAllCurrent.MonthToPostCost = @Mth)--Filter by the optional month
		AND (@MinDate IS NULL OR SMWorkCompletedAllCurrent.[Date] >= @MinDate)--Filter by the optional min date
		AND (@MaxDate IS NULL OR SMWorkCompletedAllCurrent.[Date] <= @MaxDate)--Filter by the optional max date\
	UNION
	--Finds all deleted records that need to be reversed out
	SELECT vSMGLEntry.SMWorkCompletedID, 1
	FROM dbo.vSMWorkCompletedGL
		INNER JOIN dbo.vSMGLEntry ON vSMWorkCompletedGL.CostGLEntryID = vSMGLEntry.SMGLEntryID
		LEFT JOIN dbo.SMWorkCompletedAllCurrent ON vSMWorkCompletedGL.SMWorkCompletedID = SMWorkCompletedAllCurrent.SMWorkCompletedID
		LEFT JOIN dbo.SMMiscellaneousBatch ON vSMWorkCompletedGL.SMWorkCompletedID = SMMiscellaneousBatch.SMWorkCompletedID
	WHERE vSMWorkCompletedGL.IsMiscellaneousLineType = 1 AND SMWorkCompletedAllCurrent.SMWorkCompletedID IS NULL AND SMMiscellaneousBatch.SMWorkCompletedID IS NULL
		AND vSMWorkCompletedGL.SMCo = @SMCo
)

GO
GRANT SELECT ON  [dbo].[vfSMGetWorkCompletedMiscellaneousToBeProcessed] TO [public]
GO
