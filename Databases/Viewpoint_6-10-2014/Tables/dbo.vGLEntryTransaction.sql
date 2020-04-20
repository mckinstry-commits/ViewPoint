CREATE TABLE [dbo].[vGLEntryTransaction]
(
[GLEntryID] [bigint] NOT NULL,
[GLTransaction] [int] NOT NULL,
[Source] [dbo].[bSource] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAccount] [dbo].[bGLAcct] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bTransDesc] NOT NULL,
[DetailTransGroup] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/6/11
-- Description:	Validates that a balancing set of transactions have been supplied when the GLEntry is set to have balancing transactions.
-- =============================================
CREATE TRIGGER [dbo].[vtGLEntryTransactioniud]
   ON [dbo].[vGLEntryTransaction]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1
		FROM (
				SELECT GLEntryID
				FROM INSERTED
				UNION
				SELECT GLEntryID
				FROM DELETED) ModifiedGLEntries
			INNER JOIN dbo.vGLEntry ON ModifiedGLEntries.GLEntryID = vGLEntry.GLEntryID
			INNER JOIN dbo.vGLEntryTransaction ON vGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID
		WHERE vGLEntry.TransactionsShouldBalance = 1
		GROUP BY vGLEntryTransaction.GLEntryID, vGLEntryTransaction.GLCo
		HAVING SUM(vGLEntryTransaction.Amount) <> 0)
	BEGIN
		RAISERROR('vGLEntryTransaction was attempted to be updated with an unbalanced set of debits and credits. Make sure to update all debits and credits at the same time.', 11, -1)
		ROLLBACK TRANSACTION
	END
END

GO
ALTER TABLE [dbo].[vGLEntryTransaction] ADD CONSTRAINT [PK_vGLEntryTransaction] PRIMARY KEY CLUSTERED  ([GLEntryID], [GLTransaction]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vGLEntryTransaction] WITH NOCHECK ADD CONSTRAINT [FK_vGLEntryTransaction_vGLEntry] FOREIGN KEY ([GLEntryID]) REFERENCES [dbo].[vGLEntry] ([GLEntryID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vGLEntryTransaction] NOCHECK CONSTRAINT [FK_vGLEntryTransaction_vGLEntry]
GO
