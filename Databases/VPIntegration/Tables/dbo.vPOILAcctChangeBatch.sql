CREATE TABLE [dbo].[vPOILAcctChangeBatch]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[POItemLine] [int] NOT NULL,
[NewGLCo] [dbo].[bCompany] NOT NULL,
[NewGLAcct] [dbo].[bGLAcct] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/1/11
-- Description:	Handles unlocking the approriate records for the POItemLine
-- =============================================
CREATE TRIGGER [dbo].[vtPOILAcctChangeBatchd]
   ON  [dbo].[vPOILAcctChangeBatch]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @errmsg varchar(255),
		@POCo bCompany, @BatchMonth bMonth, @BatchId bBatchID

	DECLARE @BatchesToProcess TABLE (POCo bCompany, BatchMonth bMonth, BatchId bBatchID, Processed bit)

	INSERT @BatchesToProcess
	SELECT DISTINCT Co, Mth, BatchId, 0 AS Processed
	FROM DELETED

	BatchProcessLoop:
	BEGIN
		UPDATE TOP (1) @BatchesToProcess
		SET Processed = 1, @POCo = POCo, @BatchMonth = BatchMonth, @BatchId = BatchId
		WHERE Processed = 0
		IF @@rowcount = 1
		BEGIN
			EXEC @rcode = dbo.vspPOItemLineGLAccountChangeRecordLock @POCo = @POCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @msg = @errmsg OUTPUT
			IF @rcode <> 0
			BEGIN
				GOTO Error
			END
			
			GOTO BatchProcessLoop
		END
	END

	RETURN

Error:
	SELECT @errmsg = dbo.vfToString(@errmsg) + ' - cannot delete PO Item Line GL Account Update Batch entry (POItemLineGLAccountUpdateBatch)'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/1/11
-- Description:	Handles locking the approriate records for the POItemLine
-- =============================================
CREATE TRIGGER [dbo].[vtPOILAcctChangeBatchi]
   ON  [dbo].[vPOILAcctChangeBatch]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @errmsg varchar(255),
		@POCo bCompany, @BatchMonth bMonth, @BatchId bBatchID

	DECLARE @BatchesToProcess TABLE (POCo bCompany, BatchMonth bMonth, BatchId bBatchID, Processed bit)

	INSERT @BatchesToProcess
	SELECT DISTINCT Co, Mth, BatchId, 0 AS Processed
	FROM INSERTED

	BatchProcessLoop:
	BEGIN
		UPDATE TOP (1) @BatchesToProcess
		SET Processed = 1, @POCo = POCo, @BatchMonth = BatchMonth, @BatchId = BatchId
		WHERE Processed = 0
		IF @@rowcount = 1
		BEGIN
			EXEC @rcode = dbo.vspPOItemLineGLAccountChangeRecordLock @POCo = @POCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @msg = @errmsg OUTPUT
			IF @rcode <> 0
			BEGIN
				GOTO Error
			END
			
			GOTO BatchProcessLoop
		END
	END

	RETURN

Error:
	SELECT @errmsg = dbo.vfToString(@errmsg) + ' - cannot insert PO Item Line GL Account Update Batch entry (POItemLineGLAccountUpdateBatch)'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
END

GO
ALTER TABLE [dbo].[vPOILAcctChangeBatch] ADD CONSTRAINT [IX_vPOILAcctChangeBatch] UNIQUE NONCLUSTERED  ([Co], [PO], [POItem], [POItemLine]) ON [PRIMARY]
GO
