SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************************************************************************
* Author: 
*
* Related Reports: SMGLAudit.rpt (1147)
*
* Modified By: DanK TFS-53339
*				WIP Transfers were not being included in this view. 
*********************************************************************************************************/


CREATE VIEW [dbo].[SMGLDistributionReport]
AS
	-- Work Complete WIP Transfer Records 
	SELECT vSMGLDistribution.SMCo, BatchMonth AS Mth, BatchId, vSMGLDistribution.SMWorkCompletedID, WorkOrder, NULL AS 'Scope', WorkCompleted, vSMGLEntry.Journal AS Jrnl, vSMGLDetailTransaction.[Description], vSMGLDetailTransaction.ActDate, vSMGLDetailTransaction.GLCo, vSMGLDetailTransaction.GLAccount, vSMGLDetailTransaction.Amount, CAST(CASE WHEN vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID THEN 1 ELSE 0 END AS bit) AS IsReversingEntry
	FROM dbo.vSMGLDistribution
		INNER JOIN dbo.vSMGLEntry ON vSMGLDistribution.SMGLEntryID = vSMGLEntry.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID
		INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLEntry.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
		LEFT JOIN dbo.vSMWorkCompleted ON vSMGLDistribution.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID

	UNION ALL 
	
	-- Flat Price Revenue Split WIP Transfer Records
	SELECT		vSMWIPTransferBatch.Co				AS 'SMCo',
				vSMWIPTransferBatch.Mth				AS 'Mth', 
				vSMWIPTransferBatch.BatchId			AS 'BatchId', 
				NULL								AS 'SMWorkCompletedID', 
				vSMWIPTransferBatch.WorkOrder		AS 'WorkOrder', 
				vSMWIPTransferBatch.Scope			AS 'Scope', 
				vSMWIPTransferBatch.WorkCompleted	AS 'WorkCompleted', 
				vGLDistributionInterface.Journal	AS 'Jrnl', 
				vGLDistribution.Description			AS 'Description',
				vGLDistribution.ActDate				AS 'ActDate', 
				vGLDistribution.GLCo				AS 'GLCo', 
				vGLDistribution.GLAccount			AS 'GLAccount', 
				vGLDistribution.Amount				AS 'Amount', 
				CAST(0 AS BIT)						AS 'IsReversingEntry' 
	FROM		vSMWIPTransferBatch
	INNER JOIN	vGLDistributionInterface
			ON	vGLDistributionInterface.Co			= vSMWIPTransferBatch.Co 
			AND vGLDistributionInterface.BatchId	= vSMWIPTransferBatch.BatchId
			AND vGLDistributionInterface.Mth		= vSMWIPTransferBatch.Mth
	INNER JOIN	vGLDistribution 
			ON	vGLDistribution.Co					= vSMWIPTransferBatch.Co
			AND	vGLDistribution.BatchId				= vSMWIPTransferBatch.BatchId
			AND vGLDistribution.Mth					= vSMWIPTransferBatch.Mth
			AND vGLDistribution.BatchSeq			= vSMWIPTransferBatch.BatchSeq
GO
GRANT SELECT ON  [dbo].[SMGLDistributionReport] TO [public]
GRANT INSERT ON  [dbo].[SMGLDistributionReport] TO [public]
GRANT DELETE ON  [dbo].[SMGLDistributionReport] TO [public]
GRANT UPDATE ON  [dbo].[SMGLDistributionReport] TO [public]
GRANT SELECT ON  [dbo].[SMGLDistributionReport] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMGLDistributionReport] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMGLDistributionReport] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMGLDistributionReport] TO [Viewpoint]
GO
