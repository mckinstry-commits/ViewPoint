SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMWorkCompleted]
AS
	SELECT *
	FROM dbo.SMWorkCompletedAllCurrent --It is important to have a space after the view name otherwise refreshing won't work correctly
	WHERE IsDeleted = 0
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/17/10
-- Description:	Updates non labor lines to be set as deleted so they no longer show in the view.
--				Labor lines are deleted so that the cleanup that needs to be done is done.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedViewd]
   ON  [dbo].[SMWorkCompleted]
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE vSMWorkCompleted
	SET IsDeleted = 1,
		--Any time the work completed changes we will set CostsCaptured to false so that we
		--know that the row was changed and a check needs to be made to see if it needs to be reprocessed.
		CostsCaptured = 0
	FROM dbo.vSMWorkCompleted
		INNER JOIN DELETED ON vSMWorkCompleted.SMWorkCompletedID = DELETED.KeyID
		
	-- Delete work completed when intial cost captured is false or for any labor lines
	DELETE vSMWorkCompleted
	FROM dbo.vSMWorkCompleted
		INNER JOIN DELETED ON vSMWorkCompleted.SMWorkCompletedID = DELETED.KeyID 
	WHERE 
		vSMWorkCompleted.InitialCostsCaptured = 0 AND vSMWorkCompleted.[Type] <> 4
		OR vSMWorkCompleted.[Type] = 2 --Delete labor lines right away so that the the SMWorkCompletedLabor table's delete trigger is fired.
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/12/10
-- Description:	Creates all the appropriate work completed records.
--				If any records exist but don't show up in the SMWorkCompleted view then we delete
--				the record because it means that not all corresponding records exist and so it isn't a legit record.
--				This should only happen when there is a developlment bug or someone imports or deletes records manually
-- Modified:    10/07/11 EricV Modified to unpdate LaborScope in vSMWorkCompletedLabor
--				06/25/12 EricV TK-15894 Added PRPostDate to fields inserted in the vSMWorkCompleted table
--				11/29/12 LaneG Added Nonbillable
--				4/29/13 JVH TFS-44860 Updated check to see if work completed is part of an invoice
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedViewi]
   ON  [dbo].[SMWorkCompleted]
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @IDTable TABLE (
		SMWorkCompletedID bigint,
		SMCo bCompany,
		WorkOrder int,
		WorkCompleted int)

	--Delete all the records that don't show up in SMWorkCompleted because they don't have all the corresponding records
	--to be a legitimate record.
	DELETE dbo.vSMWorkCompleted
	FROM dbo.vSMWorkCompleted
		INNER JOIN INSERTED ON vSMWorkCompleted.SMCo = INSERTED.SMCo AND vSMWorkCompleted.WorkOrder = INSERTED.WorkOrder AND vSMWorkCompleted.WorkCompleted = INSERTED.WorkCompleted
		LEFT JOIN dbo.SMWorkCompletedAll ON INSERTED.SMCo = SMWorkCompletedAll.SMCo AND INSERTED.WorkOrder = SMWorkCompletedAll.WorkOrder AND INSERTED.WorkCompleted = SMWorkCompletedAll.WorkCompleted
	WHERE SMWorkCompletedAll.KeyID IS NULL

	INSERT dbo.vSMWorkCompleted ([Type], SMCo, WorkOrder, WorkCompleted, UniqueAttchID, 
		CostCo, CostMth, CostTrans, APCo, APInUseMth, APInUseBatchId, APTLKeyID, Provisional, AutoAdded, ReferenceNo,
		PRGroup, PREndDate, PREmployee, PRPaySeq, PRPostSeq, PRPostDate, CostDetailID, NonBillable)
		OUTPUT INSERTED.SMWorkCompletedID, INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.WorkCompleted
			INTO @IDTable 
	SELECT INSERTED.[Type], INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.WorkCompleted, INSERTED.UniqueAttchID, 
		INSERTED.CostCo, INSERTED.CostMth, INSERTED.CostTrans, INSERTED.APCo, INSERTED.APInUseMth, 
		INSERTED.APInUseBatchId, INSERTED.APTLKeyID, ISNULL(INSERTED.Provisional,0), ISNULL(INSERTED.AutoAdded,0), INSERTED.ReferenceNo,
		INSERTED.PRGroup, INSERTED.PREndDate, INSERTED.PREmployee, INSERTED.PRPaySeq, INSERTED.PRPostSeq, INSERTED.PRPostDate, INSERTED.CostDetailID, ISNULL(INSERTED.NonBillable, 'N')
	FROM INSERTED

	SELECT *
	INTO #INSERTED
	FROM INSERTED

	UPDATE #INSERTED
		SET SMWorkCompletedID = IDTable.SMWorkCompletedID,
			IsSession = ISNULL(#INSERTED.IsSession, 0)
	FROM #INSERTED
		INNER JOIN @IDTable IDTable ON
			#INSERTED.SMCo = IDTable.SMCo AND
			#INSERTED.WorkOrder = IDTable.WorkOrder AND
			#INSERTED.WorkCompleted = IDTable.WorkCompleted

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedDetail', @Type = NULL,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedDetail.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedDetail.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedDetail.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedDetail.IsSession'

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedEquipment', @Type = 1,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedEquipment.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedEquipment.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedEquipment.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedEquipment.IsSession'

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedLabor', @Type = 2,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedLabor.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedLabor.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedLabor.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedLabor.IsSession'

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedMisc', @Type = 3,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedMisc.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedMisc.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedMisc.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedMisc.IsSession'

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPart', @Type = 4,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedPart.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedPart.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedPart.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedPart.IsSession'
	
	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPurchase', @Type = 5,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedPurchase.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedPurchase.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedPurchase.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedPurchase.IsSession'

	DECLARE @SMCo bCompany, @WorkOrder bigint, @Scope int, @rcode int, @msg varchar(255)
BeginLoop:		
	IF EXISTS(SELECT 1 FROM #INSERTED)
	BEGIN
		SELECT TOP 1 @SMCo=SMCo, @WorkOrder=WorkOrder, @Scope=Scope FROM #INSERTED
		
		EXEC @rcode = dbo.vspSMWorkCompletedCheckProvisional @smco = @SMCo, @workorder = @WorkOrder, @scope = @Scope, @errmsg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			--Error that happen within a trigger context cause the whole transaction to rollback
			RAISERROR(@msg, 11, 1)
			RETURN
		END

		DELETE #INSERTED WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder AND Scope=@Scope
		GOTO BeginLoop
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/12/10
-- Description:	Handles updates to the work completed records. The session copy records will be update if their invoice is in a session.
--				If the IsSession is changed it will copy/overwrite records
-- Modified:    10/07/11 EricV Modified to unpdate LaborScope in vSMWorkCompletedLabor
--				11/29/12 LaneG Added Nonbillable
--				4/29/13 JVH TFS-44860 Updated check to see if work completed is part of an invoice
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedViewu]
   ON  [dbo].[SMWorkCompleted]
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
			
	DECLARE @CostsCaptured bit, @ColumnsUpdated varbinary(max)

	IF NOT UPDATE(IsSession)
	BEGIN
		--As long as the IsSession wasn't updated then only the columns that changed should be updated in the child tables.
		--If IsSession was updated then that means records need to be backed up for the invoice review form,
		--and so the ColumnUpdated is left null indicate all columns need to be updated.
		SET @ColumnsUpdated = COLUMNS_UPDATED()

		--Any time the work completed changes we will set CostsCaptured to false so that we
		--know that the row was changed and a check needs to be made to see if it needs to be reprocessed.
		SET @CostsCaptured = 0
	END

	UPDATE vSMWorkCompleted
	SET SMCo = inserted.SMCo,
		WorkOrder = inserted.WorkOrder,
		WorkCompleted = inserted.WorkCompleted,
		[Type] = inserted.[Type],
		UniqueAttchID = inserted.UniqueAttchID,
		CostsCaptured = ISNULL(@CostsCaptured, vSMWorkCompleted.InitialCostsCaptured),
		CostCo = inserted.CostCo,
		CostMth = inserted.CostMth,
		CostTrans = inserted.CostTrans,
		APCo = inserted.APCo,
		APInUseMth = inserted.APInUseMth,
		APInUseBatchId = inserted.APInUseBatchId,
		APTLKeyID = inserted.APTLKeyID,
		Provisional = inserted.Provisional,
		AutoAdded = inserted.AutoAdded,
		ReferenceNo = inserted.ReferenceNo,
		PRGroup = inserted.PRGroup,
		PREndDate = inserted.PREndDate,
		PREmployee = inserted.PREmployee,
		PRPaySeq = inserted.PRPaySeq,
		PRPostSeq = inserted.PRPostSeq,
		CostDetailID = inserted.CostDetailID,
		NonBillable = inserted.NonBillable
	FROM vSMWorkCompleted
		INNER JOIN inserted ON vSMWorkCompleted.SMWorkCompletedID = inserted.SMWorkCompletedID
	
	SELECT *
	INTO #INSERTED
    FROM inserted
    
	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedDetail', @Type = NULL,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedDetail.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedDetail.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedDetail.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedDetail.IsSession', @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedEquipment', @Type = 1,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedEquipment.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedEquipment.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedEquipment.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedEquipment.IsSession', @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedLabor', @Type = 2,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedLabor.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedLabor.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedLabor.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedLabor.IsSession', @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedMisc', @Type = 3,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedMisc.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedMisc.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedMisc.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedMisc.IsSession', @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPart', @Type = 4,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedPart.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedPart.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedPart.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedPart.IsSession', @ColumnsUpdated = @ColumnsUpdated
	
	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPurchase', @Type = 5,
		@JoinClause = '#INSERTED.SMCo = SMWorkCompletedPurchase.SMCo AND #INSERTED.WorkOrder = SMWorkCompletedPurchase.WorkOrder AND #INSERTED.WorkCompleted = SMWorkCompletedPurchase.WorkCompleted AND #INSERTED.IsSession = SMWorkCompletedPurchase.IsSession', @ColumnsUpdated = @ColumnsUpdated

	--Prevent updates when the work completed is backed up because it will attempt to update all the columns in the view.
	IF NOT UPDATE(IsSession) AND EXISTS(SELECT 1 FROM dbo.vfColumnsUpdated(@ColumnsUpdated, 'SMWorkCompleted') WHERE ColumnsUpdated IN ('NoCharge', 'Description', 'GLCo', 'RevenueAccount', 'RevenueWIPAccount', 'PriceTotal', 'TaxType', 'TaxGroup', 'TaxCode', 'TaxBasis', 'TaxAmount'))
	BEGIN
		--When the work completed is not being backed up and changes were made that affect the invoice then update the associated values
		UPDATE vSMInvoiceLine
		SET NoCharge = inserted.NoCharge, [Description] = inserted.[Description], GLCo = inserted.GLCo, GLAccount = vfSMGetWorkCompletedGL.CurrentRevenueAccount,
			Amount = ISNULL(inserted.PriceTotal, 0), TaxGroup = inserted.TaxGroup, TaxCode = inserted.TaxCode, TaxBasis = ISNULL(inserted.TaxBasis, 0), TaxAmount = ISNULL(inserted.TaxAmount, 0)
		FROM inserted
			INNER JOIN dbo.vSMInvoiceDetail ON inserted.SMCo = vSMInvoiceDetail.SMCo AND inserted.WorkOrder = vSMInvoiceDetail.WorkOrder AND inserted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
			INNER JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
			CROSS APPLY dbo.vfSMGetWorkCompletedGL(inserted.SMWorkCompletedID)
		WHERE inserted.IsSession = 0
	END
END
GO
GRANT SELECT ON  [dbo].[SMWorkCompleted] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompleted] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompleted] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompleted] TO [public]
GRANT SELECT ON  [dbo].[SMWorkCompleted] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkCompleted] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkCompleted] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkCompleted] TO [Viewpoint]
GO
