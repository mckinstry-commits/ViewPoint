SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRSM]
AS
	SELECT vSMDetailTransaction.SMWorkCompletedID, vPRLedgerUpdateDistribution.PRCo, vPRLedgerUpdateDistribution.PRGroup, CAST(vPRLedgerUpdateDistribution.PREndDate AS datetime) PREndDate, vSMDetailTransaction.Mth,
		vSMWorkCompleted.PRPaySeq PaySeq, vSMWorkCompleted.PRPostSeq PostSeq, vSMWorkCompleted.PRPostDate, vSMWorkCompleted.PREmployee Employee,
		vSMDetailTransaction.Amount ActualLaborWages, CAST(0 AS numeric(12,2)) ActualLaborBurden, CAST(0 AS numeric(12,2)) OldActualLaborWages, CAST(0 AS numeric(12,2)) OldActualLaborBurden
	FROM dbo.vPRLedgerUpdateDistribution
			INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
			INNER JOIN dbo.vSMWorkCompleted ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
	WHERE vSMDetailTransaction.IsReversing = 0 AND vSMDetailTransaction.Posted = 0 AND vSMDetailTransaction.TransactionType = 'C'
GO
GRANT SELECT ON  [dbo].[PRSM] TO [public]
GRANT INSERT ON  [dbo].[PRSM] TO [public]
GRANT DELETE ON  [dbo].[PRSM] TO [public]
GRANT UPDATE ON  [dbo].[PRSM] TO [public]
GO
