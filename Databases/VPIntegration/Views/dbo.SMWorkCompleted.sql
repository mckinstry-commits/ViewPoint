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

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedDetail', @Type = NULL

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedEquipment', @Type = 1

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedLabor', @Type = 2

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedMisc', @Type = 3

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPart', @Type = 4

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPurchase', @Type = 5

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
	SET @ColumnsUpdated = COLUMNS_UPDATED()
	

	IF NOT UPDATE(IsSession)
	BEGIN
		--Any time the work completed changes we will set CostsCaptured to false so that we
		--know that the row was changed and a check needs to be made to see if it needs to be reprocessed.
		SET @CostsCaptured = 0
	END

	UPDATE vSMWorkCompleted
	SET SMCo = INSERTED.SMCo,
		WorkOrder = INSERTED.WorkOrder,
		WorkCompleted = INSERTED.WorkCompleted,
		[Type] = INSERTED.[Type],
		UniqueAttchID = INSERTED.UniqueAttchID,
		CostsCaptured = ISNULL(@CostsCaptured, vSMWorkCompleted.CostsCaptured),
		CostCo = INSERTED.CostCo,
		CostMth = INSERTED.CostMth,
		CostTrans = INSERTED.CostTrans,
		APCo = INSERTED.APCo,
		APInUseMth = INSERTED.APInUseMth,
		APInUseBatchId = INSERTED.APInUseBatchId,
		APTLKeyID = INSERTED.APTLKeyID,
		Provisional = INSERTED.Provisional,
		AutoAdded = INSERTED.AutoAdded,
		ReferenceNo = INSERTED.ReferenceNo,
		PRGroup = INSERTED.PRGroup,
		PREndDate = INSERTED.PREndDate,
		PREmployee = INSERTED.PREmployee,
		PRPaySeq = INSERTED.PRPaySeq,
		PRPostSeq = INSERTED.PRPostSeq,
		CostDetailID = INSERTED.CostDetailID,
		NonBillable = INSERTED.NonBillable
	FROM vSMWorkCompleted
		INNER JOIN INSERTED ON vSMWorkCompleted.SMWorkCompletedID = INSERTED.SMWorkCompletedID
	
	SELECT *
    INTO #INSERTED
    FROM INSERTED
    
	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedDetail', @Type = NULL, @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedEquipment', @Type = 1, @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedLabor', @Type = 2, @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedMisc', @Type = 3, @ColumnsUpdated = @ColumnsUpdated

	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPart', @Type = 4, @ColumnsUpdated = @ColumnsUpdated
	
	EXEC dbo.vspSMWorkCompletedDetailUpdate @SMWorkCompletedDetailTableName = 'SMWorkCompletedPurchase', @Type = 5, @ColumnsUpdated = @ColumnsUpdated
	
END
/* Change the Update Trigger End */


GO
GRANT SELECT ON  [dbo].[SMWorkCompleted] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompleted] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompleted] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompleted] TO [public]
GO
