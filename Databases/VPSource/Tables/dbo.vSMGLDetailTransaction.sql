CREATE TABLE [dbo].[vSMGLDetailTransaction]
(
[SMGLDetailTransactionID] [bigint] NOT NULL IDENTITY(1, 1),
[SMGLEntryID] [bigint] NOT NULL,
[IsTransactionForSMDerivedAccount] [bit] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAccount] [dbo].[bGLAcct] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bTransDesc] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/1/11
-- Description:	Validates that each set of debits and credits balance for a given GL Entry
-- Modified:    09/08/11 EricV  - TK-07418 Added check of BalanceNotNeeded.
-- =============================================
CREATE TRIGGER [dbo].[vtSMGLDetailTransactioniud]
   ON [dbo].[vSMGLDetailTransaction]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF EXISTS(
		SELECT 1 
		FROM INSERTED
		INNER JOIN vSMGLEntry ON INSERTED.SMGLEntryID = vSMGLEntry.SMGLEntryID
		WHERE vSMGLEntry.TransactionsShouldBalance=1
		GROUP BY INSERTED.SMGLEntryID
		HAVING SUM(Amount) <> 0) OR EXISTS (
			SELECT 1
			FROM DELETED
			INNER JOIN vSMGLEntry ON DELETED.SMGLEntryID = vSMGLEntry.SMGLEntryID
			WHERE vSMGLEntry.TransactionsShouldBalance=1
			GROUP BY DELETED.SMGLEntryID
			HAVING SUM(Amount) <> 0)
	BEGIN
		RAISERROR('vSMGLDetailTransaction was attempted to be updated with an unbalanced set of debits and credits. Make sure to update all debits and credits at the same time.', 11, -1)
		ROLLBACK TRANSACTION
	END

    IF EXISTS(
		SELECT 1 
		FROM INSERTED 
		INNER JOIN vSMGLEntry ON INSERTED.SMGLEntryID = vSMGLEntry.SMGLEntryID
		WHERE vSMGLEntry.TransactionsShouldBalance=1
		GROUP BY INSERTED.SMGLEntryID, INSERTED.GLCo
		HAVING SUM(Amount) <> 0) OR EXISTS (
			SELECT 1
			FROM DELETED
			INNER JOIN vSMGLEntry ON DELETED.SMGLEntryID = vSMGLEntry.SMGLEntryID
			WHERE vSMGLEntry.TransactionsShouldBalance=1
			GROUP BY DELETED.SMGLEntryID, DELETED.GLCo
			HAVING SUM(Amount) <> 0)
	BEGIN
		RAISERROR('vSMGLDetailTransaction was attempted to be updated with an unbalanced set of debits and credits for a given GL Company. Make sure you are adding the approriate inter-company transactions and that all debits and credits are updated at the same time.', 11, -1)
		ROLLBACK TRANSACTION
	END

END

GO
ALTER TABLE [dbo].[vSMGLDetailTransaction] ADD CONSTRAINT [PK_vSMGLDetailTransaction] PRIMARY KEY CLUSTERED  ([SMGLDetailTransactionID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMGLDetailTransaction] ADD CONSTRAINT [IX_vSMGLDetailTransaction] UNIQUE NONCLUSTERED  ([SMGLDetailTransactionID], [SMGLEntryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMGLDetailTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vSMGLDetailTransaction_vSMGLEntry] FOREIGN KEY ([SMGLEntryID]) REFERENCES [dbo].[vSMGLEntry] ([SMGLEntryID]) ON DELETE CASCADE
GO
