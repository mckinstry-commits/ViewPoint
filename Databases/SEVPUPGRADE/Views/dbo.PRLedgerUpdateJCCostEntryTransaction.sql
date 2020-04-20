SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRLedgerUpdateJCCostEntryTransaction]
AS
SELECT vPRLedgerUpdateMonth.PRCo, vPRLedgerUpdateMonth.PRGroup, vPRLedgerUpdateMonth.PREndDate, vPRLedgerUpdateMonth.Posted, vJCCostEntry.*,
	JCCostEntryTransaction.value('./@Employee','bEmployee') Employee, JCCostEntryTransaction.value('./@PaySeq','tinyint') PaySeq, JCCostEntryTransaction.value('./@PostSeq','smallint') PostSeq,
	JCCostEntryTransaction.value('./@JCCostTransaction','int') JCCostTransaction, JCCostEntryTransaction.value('./@Type','tinyint') [Type], JCCostEntryTransaction.value('./@EarnCode','bEDLCode') EarnCode, JCCostEntryTransaction.value('./@LiabilityType','bLiabilityType') LiabilityType
FROM dbo.vPRLedgerUpdateMonth
	INNER JOIN dbo.vJCCostEntry ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vJCCostEntry.PRLedgerUpdateMonthID
	CROSS APPLY DistributionXML.nodes('/JCCostEntryTransaction') JCCostEntryTransactions(JCCostEntryTransaction)
GO
GRANT SELECT ON  [dbo].[PRLedgerUpdateJCCostEntryTransaction] TO [public]
GRANT INSERT ON  [dbo].[PRLedgerUpdateJCCostEntryTransaction] TO [public]
GRANT DELETE ON  [dbo].[PRLedgerUpdateJCCostEntryTransaction] TO [public]
GRANT UPDATE ON  [dbo].[PRLedgerUpdateJCCostEntryTransaction] TO [public]
GO
