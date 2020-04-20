SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[SMGLDistributionReport]
AS
	SELECT vSMGLDistribution.SMCo, BatchMonth AS Mth, BatchId, vSMGLDistribution.SMWorkCompletedID, WorkOrder, WorkCompleted, vSMGLEntry.Journal AS Jrnl, vSMGLDetailTransaction.[Description], vSMGLDetailTransaction.ActDate, vSMGLDetailTransaction.GLCo, vSMGLDetailTransaction.GLAccount, vSMGLDetailTransaction.Amount, CAST(CASE WHEN vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID THEN 1 ELSE 0 END AS bit) AS IsReversingEntry
	FROM dbo.vSMGLDistribution
		INNER JOIN dbo.vSMGLEntry ON vSMGLDistribution.SMGLEntryID = vSMGLEntry.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID
		INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLEntry.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
		LEFT JOIN dbo.vSMWorkCompleted ON vSMGLDistribution.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID







GO
GRANT SELECT ON  [dbo].[SMGLDistributionReport] TO [public]
GRANT INSERT ON  [dbo].[SMGLDistributionReport] TO [public]
GRANT DELETE ON  [dbo].[SMGLDistributionReport] TO [public]
GRANT UPDATE ON  [dbo].[SMGLDistributionReport] TO [public]
GO
