CREATE TABLE [dbo].[vSMWorkCompletedPurchase]
(
[SMWorkCompletedPurchaseID] [bigint] NOT NULL IDENTITY(1, 1),
[SMWorkCompletedID] [bigint] NOT NULL,
[IsSession] [bit] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL,
[WorkCompleted] [int] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Quantity] [dbo].[bUnits] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[CostRate] [dbo].[bUnitCost] NULL,
[CostECM] [dbo].[bECM] NULL,
[ProjCost] [dbo].[bDollar] NULL,
[ActualUnits] [dbo].[bUnits] NULL CONSTRAINT [DF_vSMWorkCompletedPurchase_ActualUnits] DEFAULT ((0)),
[ActualCost] [dbo].[bDollar] NULL,
[POCo] [dbo].[bCompany] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[POItemLine] [int] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Part] [dbo].[bMatl] NULL,
[PriceUM] [dbo].[bUM] NULL,
[PriceECM] [dbo].[bECM] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedPurchase_bHQUM_PriceUM] FOREIGN KEY ([PriceUM]) REFERENCES [dbo].[bHQUM] ([UM])
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD
CONSTRAINT [FK_vSMWorkCompletedPurchase_bHQUM_UM] FOREIGN KEY ([UM]) REFERENCES [dbo].[bHQUM] ([UM])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/6/12
-- Description:	TK-20063 - In the 2013Q1 release a change was made from allowing multiple work completed to be
--				created for the same PO Item Line to automatically creating a work completed line
--				when the PO Item line is created, however the existing data was not consolidated
--				so for old data there is still the possibility that multiple work completed records
--				exists and when the corresponding PO Item Line is deleted then the work completed needs
--				to be deleted. Once partial work completed invoicing is done then the multiple work completed
--				tied to the same po item line will be consolidated into 1 and there will no longer be any 
--				need for this trigger.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedPurchaseu]
   ON  [dbo].[vSMWorkCompletedPurchase]
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON; 
	
	DECLARE @msg varchar(255)
	
	--If the work completed is part of an invoice that needs to be processed prevent the changes.
	SELECT @msg = 'A customer invoice for work order: SMCo ' + dbo.vfToString(vSMWorkCompletedDetail.SMCo) + ' - WorkOrder ' + dbo.vfToString(vSMWorkCompletedDetail.WorkOrder) + ' needs to be processed in order for the po distribution to be modified.'
	FROM DELETED
		INNER JOIN dbo.vSMWorkCompletedDetail ON DELETED.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID
		INNER JOIN dbo.vSMInvoiceSession ON vSMWorkCompletedDetail.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
		LEFT JOIN dbo.vPOItemLine ON DELETED.POCo = vPOItemLine.POCo AND DELETED.PO = vPOItemLine.PO AND DELETED.POItem = vPOItemLine.POItem AND DELETED.POItemLine = vPOItemLine.POItemLine
	WHERE DELETED.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL
	IF @@rowcount <> 0
	BEGIN
		RAISERROR(@msg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN
	END

	--Clear costs for the work completed if it still part of an invoice
	UPDATE vSMWorkCompletedDetail
	SET PriceRate = NULL
	FROM DELETED
		INNER JOIN dbo.vSMWorkCompletedDetail ON DELETED.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID
		LEFT JOIN dbo.vPOItemLine ON DELETED.POCo = vPOItemLine.POCo AND DELETED.PO = vPOItemLine.PO AND DELETED.POItem = vPOItemLine.POItem AND DELETED.POItemLine = vPOItemLine.POItemLine
	WHERE DELETED.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL AND EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedDetail WHERE DELETED.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.SMInvoiceID IS NOT NULL)

	UPDATE vSMWorkCompletedPurchase
	SET CostRate = NULL, CostECM = NULL, ProjCost = NULL, ActualUnits = NULL, ActualCost = NULL, POCo = NULL, PO = NULL, POItem = NULL, POItemLine = NULL, PriceUM  = NULL, PriceECM  = NULL,
		-- Copy PO Item material and description to not lose this information
		MatlGroup = bPOIT.MatlGroup, Part = bPOIT.Material, [Description] = bPOIT.[Description]
	FROM DELETED
		INNER JOIN dbo.vSMWorkCompletedPurchase ON DELETED.SMWorkCompletedID = vSMWorkCompletedPurchase.SMWorkCompletedID
		INNER JOIN dbo.bPOIT ON DELETED.POCo = bPOIT.POCo AND DELETED.PO = bPOIT.PO AND DELETED.POItem = bPOIT.POItem 
		LEFT JOIN dbo.vPOItemLine ON DELETED.POCo = vPOItemLine.POCo AND DELETED.PO = vPOItemLine.PO AND DELETED.POItem = vPOItemLine.POItem AND DELETED.POItemLine = vPOItemLine.POItemLine
	WHERE DELETED.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL AND EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedDetail WHERE DELETED.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.SMInvoiceID IS NOT NULL)

	DELETE vSMWorkCompleted
	FROM DELETED
		INNER JOIN dbo.vSMWorkCompleted ON DELETED.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		LEFT JOIN dbo.vPOItemLine ON DELETED.POCo = vPOItemLine.POCo AND DELETED.PO = vPOItemLine.PO AND DELETED.POItem = vPOItemLine.POItem AND DELETED.POItemLine = vPOItemLine.POItemLine
	WHERE DELETED.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL AND NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedDetail WHERE DELETED.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.SMInvoiceID IS NOT NULL)
END

GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] ADD CONSTRAINT [PK_vSMWorkCompletedPurchase] PRIMARY KEY CLUSTERED  ([SMWorkCompletedPurchaseID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] ADD CONSTRAINT [IX_vSMWorkCompletedPurchase_SMWorkCompletedID_IsSession] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [IsSession]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] ADD CONSTRAINT [IX_vSMWorkCompletedPurchase_WorkOrder_WorkCompleted_SMCo_IsSession] UNIQUE NONCLUSTERED  ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedPurchase_vPOItemLine] FOREIGN KEY ([POCo], [PO], [POItem], [POItemLine]) REFERENCES [dbo].[vPOItemLine] ([POCo], [PO], [POItem], [POItemLine]) ON DELETE SET NULL
GO

ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedPurchase_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted])
GO

ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedPurchase_vSMWorkCompletedDetail] FOREIGN KEY ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) REFERENCES [dbo].[vSMWorkCompletedDetail] ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) ON DELETE CASCADE ON UPDATE CASCADE
GO
