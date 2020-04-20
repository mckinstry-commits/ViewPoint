SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PRLedgerUpdateGLEntryTransaction]
AS
SELECT vPRLedgerUpdateMonth.PRCo, vPRLedgerUpdateMonth.PRGroup, vPRLedgerUpdateMonth.PREndDate, vPRLedgerUpdateMonth.Posted, vGLEntry.*,
	GLEntryTransaction.value('./@Employee','bEmployee') Employee, GLEntryTransaction.value('./@PaySeq','tinyint') PaySeq, GLEntryTransaction.value('./@PostSeq','smallint') PostSeq,
	GLEntryTransaction.value('./@GLTransaction','int') GLTransaction, GLEntryTransaction.value('./@Type','tinyint') [Type], GLEntryTransaction.value('./@EarnCode','bEDLCode') EarnCode, GLEntryTransaction.value('./@LiabilityType','bLiabilityType') LiabilityType
FROM dbo.vPRLedgerUpdateMonth
	INNER JOIN dbo.vGLEntry ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vGLEntry.PRLedgerUpdateMonthID
	CROSS APPLY DistributionXML.nodes('/GLEntryTransaction') GLEntryTransactions(GLEntryTransaction)
GO
GRANT SELECT ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [public]
GRANT INSERT ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [public]
GRANT DELETE ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [public]
GRANT UPDATE ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [public]
GRANT SELECT ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRLedgerUpdateGLEntryTransaction] TO [Viewpoint]
GO
