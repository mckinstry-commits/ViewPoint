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
--				to be deleted.
-- Modified:	JVH 4/29/13 TFS-44860 Updated check to see if work completed is part of an invoice
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedPurchaseu]
   ON  [dbo].[vSMWorkCompletedPurchase]
   AFTER UPDATE
AS 
BEGIN

	SET NOCOUNT ON; 
	
	DECLARE @msg varchar(255)
	
	--If the work completed is part of an invoice that needs to be processed prevent the changes.
	SELECT @msg = 'A customer invoice for work order: SMCo ' + dbo.vfToString(deleted.SMCo) + ' - WorkOrder ' + dbo.vfToString(deleted.WorkOrder) + ' needs to be processed in order for the po distribution to be modified.'
	FROM deleted
		INNER JOIN dbo.vSMInvoiceDetail ON deleted.SMCo = vSMInvoiceDetail.SMCo AND deleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND deleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		INNER JOIN dbo.vSMInvoice ON vSMInvoiceDetail.SMCo = vSMInvoice.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoice.Invoice
		INNER JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
		LEFT JOIN dbo.vPOItemLine ON deleted.POCo = vPOItemLine.POCo AND deleted.PO = vPOItemLine.PO AND deleted.POItem = vPOItemLine.POItem AND deleted.POItemLine = vPOItemLine.POItemLine
	WHERE deleted.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL
	IF @@rowcount <> 0
	BEGIN
		RAISERROR(@msg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN
	END

	--Clear costs for the work completed if it still part of an invoice
	UPDATE vSMWorkCompletedDetail
	SET PriceRate = NULL
	FROM deleted
		INNER JOIN dbo.vSMWorkCompletedDetail ON deleted.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID
		INNER JOIN dbo.vSMInvoiceDetail ON deleted.SMCo = vSMInvoiceDetail.SMCo AND deleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND deleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		LEFT JOIN dbo.vPOItemLine ON deleted.POCo = vPOItemLine.POCo AND deleted.PO = vPOItemLine.PO AND deleted.POItem = vPOItemLine.POItem AND deleted.POItemLine = vPOItemLine.POItemLine
	WHERE deleted.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL

	UPDATE vSMWorkCompletedPurchase
	SET CostRate = NULL, CostECM = NULL, ProjCost = NULL, ActualUnits = NULL, ActualCost = NULL, POCo = NULL, PO = NULL, POItem = NULL, POItemLine = NULL, PriceUM  = NULL, PriceECM  = NULL,
		-- Copy PO Item material and description to not lose this information
		MatlGroup = bPOIT.MatlGroup, Part = bPOIT.Material, [Description] = bPOIT.[Description]
	FROM deleted
		INNER JOIN dbo.vSMWorkCompletedPurchase ON deleted.SMWorkCompletedID = vSMWorkCompletedPurchase.SMWorkCompletedID
		INNER JOIN dbo.vSMInvoiceDetail ON deleted.SMCo = vSMInvoiceDetail.SMCo AND deleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND deleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		INNER JOIN dbo.bPOIT ON deleted.POCo = bPOIT.POCo AND deleted.PO = bPOIT.PO AND deleted.POItem = bPOIT.POItem 
		LEFT JOIN dbo.vPOItemLine ON deleted.POCo = vPOItemLine.POCo AND deleted.PO = vPOItemLine.PO AND deleted.POItem = vPOItemLine.POItem AND deleted.POItemLine = vPOItemLine.POItemLine
	WHERE deleted.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL

	DELETE vSMWorkCompleted
	FROM deleted
		INNER JOIN dbo.vSMWorkCompleted ON deleted.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		LEFT JOIN dbo.vSMInvoiceDetail ON deleted.SMCo = vSMInvoiceDetail.SMCo AND deleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND deleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		LEFT JOIN dbo.vPOItemLine ON deleted.POCo = vPOItemLine.POCo AND deleted.PO = vPOItemLine.PO AND deleted.POItem = vPOItemLine.POItem AND deleted.POItemLine = vPOItemLine.POItemLine
	WHERE deleted.POItemLine IS NOT NULL AND vPOItemLine.POItemLine IS NULL AND vSMInvoiceDetail.SMInvoiceDetailID IS NULL
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
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedPurchase_bHQUM_PriceUM] FOREIGN KEY ([PriceUM]) REFERENCES [dbo].[bHQUM] ([UM])
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedPurchase_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted])
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedPurchase_bHQUM_UM] FOREIGN KEY ([UM]) REFERENCES [dbo].[bHQUM] ([UM])
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedPurchase_vSMWorkCompletedDetail] FOREIGN KEY ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) REFERENCES [dbo].[vSMWorkCompletedDetail] ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] NOCHECK CONSTRAINT [FK_vSMWorkCompletedPurchase_vPOItemLine]
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] NOCHECK CONSTRAINT [FK_vSMWorkCompletedPurchase_bHQUM_PriceUM]
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] NOCHECK CONSTRAINT [FK_vSMWorkCompletedPurchase_vSMWorkCompleted]
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] NOCHECK CONSTRAINT [FK_vSMWorkCompletedPurchase_bHQUM_UM]
GO
ALTER TABLE [dbo].[vSMWorkCompletedPurchase] NOCHECK CONSTRAINT [FK_vSMWorkCompletedPurchase_vSMWorkCompletedDetail]
GO
