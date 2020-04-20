CREATE TABLE [dbo].[vSMWorkCompletedGL]
(
[SMWorkCompletedID] [bigint] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[IsMiscellaneousLineType] [bit] NOT NULL,
[CostGLEntryID] [bigint] NULL,
[CostGLDetailTransactionEntryID] [bigint] NULL,
[CostGLDetailTransactionID] [bigint] NULL,
[RevenueGLEntryID] [bigint] NULL,
[RevenueGLDetailTransactionEntryID] [bigint] NULL,
[RevenueGLDetailTransactionID] [bigint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/2/11
-- Description:	Trigger validation for vSMWorkCompletedGL
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedGLiu]
   ON  [dbo].[vSMWorkCompletedGL]
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF EXISTS(
		SELECT 1 
		FROM INSERTED
			INNER JOIN vSMGLDetailTransaction ON (INSERTED.CostGLEntryID = vSMGLDetailTransaction.SMGLEntryID AND vSMGLDetailTransaction.IsTransactionForSMDerivedAccount = 0) OR INSERTED.CostGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
			INNER JOIN vSMGLEntry ON  vSMGLDetailTransaction.SMGLEntryID = vSMGLEntry.SMGLEntryID
		WHERE dbo.vfEqualsNull(CostGLEntryID) | dbo.vfEqualsNull(CostGLDetailTransactionID) = 0
			AND vSMGLEntry.TransactionsShouldBalance=1
		GROUP BY INSERTED.SMWorkCompletedID
		HAVING SUM(Amount) <> 0)
	BEGIN
		RAISERROR('The set of debits and credits that are for the CostGLEntryID and are not for an SM derived account along with the debit or credit for the CostGLDetailTransactionID must sum to 0.', 11, -1)
		ROLLBACK TRANSACTION
	END
	
	    IF EXISTS(
		SELECT 1 
		FROM INSERTED
			INNER JOIN vSMGLDetailTransaction ON (INSERTED.RevenueGLEntryID = vSMGLDetailTransaction.SMGLEntryID AND vSMGLDetailTransaction.IsTransactionForSMDerivedAccount = 0) OR INSERTED.RevenueGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
			INNER JOIN vSMGLEntry ON  vSMGLDetailTransaction.SMGLEntryID = vSMGLEntry.SMGLEntryID
		WHERE dbo.vfEqualsNull(RevenueGLEntryID) | dbo.vfEqualsNull(RevenueGLDetailTransactionID) = 0
			AND vSMGLEntry.TransactionsShouldBalance=1
		GROUP BY INSERTED.SMWorkCompletedID
		HAVING SUM(Amount) <> 0)
	BEGIN
		RAISERROR('The set of debits and credits that are for the RevenueGLEntryID and are not for an SM derived account along with the debit or credit for the RevenueGLDetailTransactionID must sum to 0.', 11, -1)
		ROLLBACK TRANSACTION
	END
END

GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] ADD CONSTRAINT [PK_vSMWorkCompletedGL] PRIMARY KEY CLUSTERED  ([SMWorkCompletedID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_CostGLDetailTransactionEntry] FOREIGN KEY ([CostGLDetailTransactionEntryID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMGLEntry] ([SMGLEntryID], [SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLDetailTransaction_CostDetailTransaction] FOREIGN KEY ([CostGLDetailTransactionID], [CostGLDetailTransactionEntryID]) REFERENCES [dbo].[vSMGLDetailTransaction] ([SMGLDetailTransactionID], [SMGLEntryID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_CostGLEntry] FOREIGN KEY ([CostGLEntryID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMGLEntry] ([SMGLEntryID], [SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_RevenueGLDetailTransactionEntry] FOREIGN KEY ([RevenueGLDetailTransactionEntryID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMGLEntry] ([SMGLEntryID], [SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLDetailTransaction_RevenueDetailTransaction] FOREIGN KEY ([RevenueGLDetailTransactionID], [RevenueGLDetailTransactionEntryID]) REFERENCES [dbo].[vSMGLDetailTransaction] ([SMGLDetailTransactionID], [SMGLEntryID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_RevenueGLEntry] FOREIGN KEY ([RevenueGLEntryID], [SMWorkCompletedID]) REFERENCES [dbo].[vSMGLEntry] ([SMGLEntryID], [SMWorkCompletedID])
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] NOCHECK CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_CostGLDetailTransactionEntry]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] NOCHECK CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLDetailTransaction_CostDetailTransaction]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] NOCHECK CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_CostGLEntry]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] NOCHECK CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_RevenueGLDetailTransactionEntry]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] NOCHECK CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLDetailTransaction_RevenueDetailTransaction]
GO
ALTER TABLE [dbo].[vSMWorkCompletedGL] NOCHECK CONSTRAINT [FK_vSMWorkCompletedGL_vSMGLEntry_RevenueGLEntry]
GO
