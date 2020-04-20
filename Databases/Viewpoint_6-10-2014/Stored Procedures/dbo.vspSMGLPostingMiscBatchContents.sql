SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMGLPostingMiscBatchContents]
   /***********************************************************
    * Created:  ECV 03/31/11
    *
    * Return a recordset of the contents of the specified SM batch
    * based on the Source of the batch.
    *
    * INPUT PARAMETERS
    *   @SMCo           SM Co#
    *   @mth            Posting Month
    *   @BatchId		Batch ID
    *
    * OUTPUT PARAMETERS
    *   @msg            error message if something went wrong
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    * Modified:
    *			JB 12/6/12	Removed PO Receipts source.
	*			SKA 04/08/2013 - TFS Bug 38871 - Cost should be negative if its a deleted entry to be processed
	*			JVH 6/25/13	   - TFS - 53341 Removed showing WIP batch records
    *****************************************************/
(@SMCo bCompany, @mth bMonth, @BatchId int, @Source varchar(15), @msg varchar(255)=NULL OUTPUT)
AS
SET NOCOUNT ON

SET @msg=NULL

IF @Source='SMLedgerUp'
BEGIN
	SELECT SMWorkCompletedAllCurrent.WorkOrder AS [Work Order], SMWorkCompletedAllCurrent.Scope, SMWorkCompletedAllCurrent.WorkCompleted AS [Work Completed], SMWorkCompletedAllCurrent.[Date], SMWorkCompletedAllCurrent.[Description], 
		case when SMWorkCompletedAllCurrent.IsDeleted = 1 then SMWorkCompletedAllCurrent.ActualCost * -1 else SMWorkCompletedAllCurrent.ActualCost end as ActualCost --Bug 38871
	FROM SMMiscellaneousBatch
		INNER JOIN SMWorkCompletedAllCurrent ON SMMiscellaneousBatch.SMWorkCompletedID = SMWorkCompletedAllCurrent.SMWorkCompletedID
	WHERE SMMiscellaneousBatch.Co = @SMCo AND SMMiscellaneousBatch.BatchId = @BatchId AND SMMiscellaneousBatch.Mth = @mth
END
ELSE IF @Source='SMEquipUse'
BEGIN
	SELECT BatchTransType AS [Line Type], WorkOrder AS [Work Order], Scope, WorkCompleted AS [Work Completed], ActualDate AS [Actual Date], GLCo, GLAcct AS [GL Acct], OffsetGLCo AS [Offset GLCo], OffsetGLAcct AS [Offset GL Acct],
		EMCo, Equipment, RevCode AS [Rev Code], WorkUnits AS [Work Units], TimeUnits AS [Time Units], Dollars Amount, SMWorkCompletedID
	FROM dbo.SMEMUsageBatch
	WHERE Co = @SMCo AND BatchMonth = @mth AND BatchId = @BatchId
END
ELSE IF @Source='SM Inv'
BEGIN
	SELECT SMINBatch.WorkOrder AS [Work Order], SMINBatch.Scope, SMWorkCompletedAllCurrent.WorkCompleted AS [Work Completed], SMINBatch.SaleDate AS [Sale Date], SMINBatch.INCo, SMINBatch.INLocation AS [IN Location], SMINBatch.MaterialGroup AS [Material Group], SMINBatch.Material, SMINBatch.MaterialDescription AS [Material Description], 
		SMINBatch.SMGLCo, SMINBatch.SMCostGLAccount AS [SM Cost GL Acct], SMINBatch.INGLCo, SMINBatch.CostOfGoodsGLAccount AS [Cost Of Goods GL Acct], SMINBatch.TotalCost AS [Total Cost],
		SMINBatch.ServiceSalesGLAccount AS [Service Sales GL Acct], SMINBatch.TotalPrice AS [Total Price], SMWorkCompletedAllCurrent.SMWorkCompletedID
	FROM dbo.SMINBatch
		INNER JOIN dbo.SMWorkCompletedAllCurrent ON SMINBatch.SMWorkCompletedID = SMWorkCompletedAllCurrent.SMWorkCompletedID
	WHERE SMINBatch.SMCo = @SMCo AND SMINBatch.BatchId = @BatchId AND SMINBatch.Mth = @mth
END
ELSE IF @Source='SMAmortize'
BEGIN
	SELECT Agreement, Revision, [Service], GLCo, AgreementRevDefGLAcct AS [Deferral GL Acct], AgreementRevGLAcct AS [Revenue GL Acct], Amount
	FROM dbo.vSMAgreementAmrtBatch
	WHERE vSMAgreementAmrtBatch.Co = @SMCo AND vSMAgreementAmrtBatch.BatchId = @BatchId AND vSMAgreementAmrtBatch.Mth = @mth
END
ELSE
BEGIN
	SELECT NULL [Unknown Source] WHERE 0=1
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspSMGLPostingMiscBatchContents] TO [public]
GO
