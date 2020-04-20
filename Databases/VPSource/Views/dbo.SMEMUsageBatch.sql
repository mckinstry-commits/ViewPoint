SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMEMUsageBatch]
AS
	SELECT 
		SMWorkCompletedAllCurrent.SMWorkCompletedID,
		vSMWorkCompletedBatch.BatchCo AS Co, --Needed for vspHQBCTableRowCount
		vSMWorkCompletedBatch.BatchMonth AS Mth, --Needed for vspHQBCTableRowCount
		vSMWorkCompletedBatch.BatchMonth,
		vSMWorkCompletedBatch.BatchId,
		vSMWorkCompletedBatch.BatchSeq,
		vSMWorkCompletedBatch.IsProcessed,
		CASE SMWorkCompletedAllCurrent.InitialCostsCaptured
			WHEN 0 THEN 'A'
			WHEN 1 THEN
				CASE SMWorkCompletedAllCurrent.IsDeleted
					WHEN 0 THEN 'C'
					WHEN 1 THEN 'D'
				END
		END AS BatchTransType,
		SMWorkCompletedAllCurrent.SMCo, SMWorkCompletedAllCurrent.WorkOrder, SMWorkCompletedAllCurrent.WorkCompleted, SMWorkCompletedAllCurrent.Scope,
		SMWorkCompletedAllCurrent.EMCo, SMWorkCompletedAllCurrent.EMGroup, SMWorkCompletedAllCurrent.Equipment,
		SMWorkCompletedAllCurrent.RevCode, ISNULL(EMDR.GLCo, EMCO.GLCo) AS GLCo, EMDR.GLAcct AS GLAcct, WorkCompletedAccount.GLCo AS OffsetGLCo, WorkCompletedAccount.GLAccount AS OffsetGLAcct,
		EMEquipmentRevCodeSetup.Category, EMEquipmentRevCodeSetup.Basis AS RevBasis, EMEquipmentRevCodeSetup.WorkUM, SMWorkCompletedAllCurrent.WorkUnits, EMEquipmentRevCodeSetup.TimeUM, SMWorkCompletedAllCurrent.TimeUnits,
		SMWorkCompletedAllCurrent.ActualCost AS Dollars, SMWorkCompletedAllCurrent.CostRate AS RevRate, SMWorkCompletedAllCurrent.[Date] AS ActualDate, SMWorkOrder.CustGroup, SMWorkOrder.Customer,
		ReversingEntry.OldScope,
		ReversingEntry.OldEMCo,
		ReversingEntry.OldEMGroup,
		ReversingEntry.OldEquipment,
		ReversingEntry.OldRevCode,
		ReversingEntry.OldGLCo,
		ReversingEntry.OldGLAcct,
		ReversingEntry.OldOffsetGLCo,
		ReversingEntry.OldOffsetGLAcct,
		CASE 
		  WHEN ReversingEntry.Ranking IS NULL THEN NULL
		  WHEN ReversingEntry.Ranking = 0 THEN ReversingEntry.Category
		  ELSE EMEquipmentRevCodeSetup.Category
		END AS OldCategory,
		CASE 
		  WHEN ReversingEntry.Ranking IS NULL THEN NULL
		  ELSE EMEquipmentRevCodeSetup.Basis 
		END AS OldRevBasis,
		CASE 
		  WHEN ReversingEntry.Ranking IS NULL THEN NULL
		  WHEN ReversingEntry.Ranking = 0 THEN ReversingEntry.UM
		  ELSE EMEquipmentRevCodeSetup.WorkUM
		END AS OldWorkUM,
		ReversingEntry.OldWorkUnits,
		CASE 
		  WHEN ReversingEntry.Ranking IS NULL THEN NULL
		  WHEN ReversingEntry.Ranking = 0 THEN ReversingEntry.TimeUM
		  ELSE EMEquipmentRevCodeSetup.TimeUM
		END AS OldTimeUM,
		ReversingEntry.OldTimeUnits,
		ReversingEntry.OldDollars,
		ReversingEntry.OldRevRate,
		ReversingEntry.OldActualDate,
		ReversingEntry.OldCustGroup,
		ReversingEntry.OldCustomer,
		ReversingEntry.Ranking
	FROM dbo.vSMWorkCompletedBatch
		INNER JOIN dbo.SMWorkCompletedAllCurrent ON vSMWorkCompletedBatch.SMWorkCompletedID = SMWorkCompletedAllCurrent.SMWorkCompletedID
		INNER JOIN dbo.SMWorkOrder ON SMWorkCompletedAllCurrent.SMCo = SMWorkOrder.SMCo AND SMWorkCompletedAllCurrent.WorkOrder = SMWorkOrder.WorkOrder
		INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompletedAllCurrent.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompletedAllCurrent.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompletedAllCurrent.Scope = SMWorkOrderScope.Scope
		CROSS APPLY dbo.vfSMGetWorkCompletedAccount(SMWorkCompletedAllCurrent.SMWorkCompletedID, 'C', CASE WHEN SMWorkOrderScope.IsTrackingWIP = 'Y' AND SMWorkOrderScope.IsComplete = 'N' THEN 1 ELSE 0 END) WorkCompletedAccount
		OUTER APPLY dbo.vfEMEquipmentRevCodeSetup(SMWorkCompletedAllCurrent.EMCo, SMWorkCompletedAllCurrent.Equipment, SMWorkCompletedAllCurrent.EMGroup, SMWorkCompletedAllCurrent.RevCode) EMEquipmentRevCodeSetup  
		
		--Retrieve the gl accounts from EM
		--Make sure to account for improper setup by using left joins
		LEFT JOIN dbo.EMCO ON SMWorkCompletedAllCurrent.EMCo = EMCO.EMCo
		LEFT JOIN dbo.EMDR ON SMWorkCompletedAllCurrent.EMCo = EMDR.EMCo AND SMWorkCompletedAllCurrent.EMGroup = EMDR.EMGroup AND EMEquipmentRevCodeSetup.Department = EMDR.Department AND SMWorkCompletedAllCurrent.RevCode = EMDR.RevCode

		--Retrieve the old values if available
		LEFT JOIN dbo.vSMWorkCompletedGL ON SMWorkCompletedAllCurrent.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
		LEFT JOIN dbo.vSMGLDetailTransaction ON vSMWorkCompletedGL.CostGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
		OUTER APPLY (
			SELECT TOP 1 *
			FROM
				(
				SELECT
					SMScope AS OldScope,
					EMCo AS OldEMCo,
					EMGroup AS OldEMGroup, Equipment AS OldEquipment,
					RevCode AS OldRevCode, GLCo AS OldGLCo, RevGLAcct AS OldGLAcct, ISNULL(vSMGLDetailTransaction.GLCo, ExpGLCo) AS OldOffsetGLCo, ISNULL(vSMGLDetailTransaction.GLAccount, ExpGLAcct) AS OldOffsetGLAcct,
					-WorkUnits AS OldWorkUnits, -TimeUnits AS OldTimeUnits,
					-Dollars AS OldDollars, RevRate AS OldRevRate, ActualDate AS OldActualDate,
					CustGroup AS OldCustGroup, Customer AS OldCustomer,
					UM, 
					TimeUM, 
					Category, 0 AS Ranking
				FROM dbo.bEMRD
				WHERE bEMRD.EMCo = SMWorkCompletedAllCurrent.CostCo AND bEMRD.Mth = SMWorkCompletedAllCurrent.CostMth AND bEMRD.Trans = SMWorkCompletedAllCurrent.CostTrans
				UNION ALL
				SELECT
					SMWorkCompletedAllCurrent.Scope,
					SMWorkCompletedAllCurrent.EMCo,
					SMWorkCompletedAllCurrent.EMGroup, SMWorkCompletedAllCurrent.Equipment,
					SMWorkCompletedAllCurrent.RevCode, ISNULL(EMDR.GLCo, EMCO.GLCo), EMDR.GLAcct, ISNULL(vSMGLDetailTransaction.GLCo, WorkCompletedAccount.GLCo), ISNULL(vSMGLDetailTransaction.GLAccount, WorkCompletedAccount.GLAccount),
					-SMWorkCompletedAllCurrent.WorkUnits, -SMWorkCompletedAllCurrent.TimeUnits,
					-SMWorkCompletedAllCurrent.ActualCost, SMWorkCompletedAllCurrent.CostRate, SMWorkCompletedAllCurrent.[Date],
					SMWorkOrder.CustGroup, SMWorkOrder.Customer,
					'bad' AS UM,
					'bad' AS TimeUM,
					'bad' AS Category, 1 AS Ranking
				) OldValues
			WHERE SMWorkCompletedAllCurrent.InitialCostsCaptured = 1
			ORDER BY OldValues.Ranking
		) ReversingEntry



GO
GRANT SELECT ON  [dbo].[SMEMUsageBatch] TO [public]
GRANT INSERT ON  [dbo].[SMEMUsageBatch] TO [public]
GRANT DELETE ON  [dbo].[SMEMUsageBatch] TO [public]
GRANT UPDATE ON  [dbo].[SMEMUsageBatch] TO [public]
GO
