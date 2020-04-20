SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMDetailTransactionExtended]
AS

SELECT SMDetailTransaction.*, SMWorkOrder.SMCo, SMWorkOrder.WorkOrder,
	CASE WHEN SMDetailTransaction.Amount > 0 OR (SMDetailTransaction.Amount = 0 AND SMDetailTransaction.TransactionType = 'C') THEN ABS(Amount) END Debit,
	CASE WHEN SMDetailTransaction.Amount < 0 OR (SMDetailTransaction.Amount = 0 AND SMDetailTransaction.TransactionType = 'R') THEN ABS(Amount) END Credit
FROM dbo.SMDetailTransaction
	LEFT JOIN dbo.SMWorkOrder ON SMWorkOrder.SMWorkOrderID = SMDetailTransaction.SMWorkOrderID
GO
GRANT SELECT ON  [dbo].[SMDetailTransactionExtended] TO [public]
GRANT INSERT ON  [dbo].[SMDetailTransactionExtended] TO [public]
GRANT DELETE ON  [dbo].[SMDetailTransactionExtended] TO [public]
GRANT UPDATE ON  [dbo].[SMDetailTransactionExtended] TO [public]
GRANT SELECT ON  [dbo].[SMDetailTransactionExtended] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDetailTransactionExtended] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDetailTransactionExtended] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDetailTransactionExtended] TO [Viewpoint]
GO
