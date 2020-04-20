SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 2/20/2011
-- Description:	SM batch posting for IN usage
-- Modified: 4/15/2011 AL - Added logic for deterministic IM posting based on interface values.
--				09/13/2011	CHS - TK-08333 changed 'SM Sale' to 'AR Sale'
--				02/21/2012	TRL - TK-12770 added code to update JC Cost Detail to JCCD
--				03/02/2012 TRL - TK- 12858 add new paramter for JC TransType 
--				05/25/2012 TRL TK - 15053 removed @JCTransType Parameter for vspSMJobCostDetailInsert
--				05/14/2013 EricV - TFS-50047 Added the GL Interface Level to the call to the procedure vspSMWorkCompletedPost.

-- =============================================
CREATE procedure [dbo].[vspSMINBatchPost]
(@SMCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @DatePosted bDate = NULL, @Source bSource, @TableName varchar(10), @msg varchar(255) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int

	--Make sure the batch can be posted and set it as posting in progress.
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @Source = @Source, @TableName = @TableName, @DatePosted = @DatePosted, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	DECLARE @BatchSeq int, @INCo bCompany, @CurrentID bigint, @WorkOrder int, @WorkCompleted int, 
		@SeqErrMsg varchar(255), @INTrans bTrans, @IsReversingEntry bit, @SMGLDistributionID bigint,
		@GLCo bCompany, @Scope int, @SMWorkCompletedID bigint,
		@PostToIN bYN,
		@GLLvl tinyint,
		@BatchNotes varchar(max)
		
	SET @CurrentID = 0
	
	SELECT @PostToIN = UseINInterface, @GLLvl = CASE GLLvl WHEN 'NoUpdate' THEN 0 WHEN 'Summary' THEN 1 WHEN 'Detail' THEN 2 END
	FROM dbo.vSMCO 
	WHERE SMCo = @SMCo
	
	IF @PostToIN = 'Y'
	BEGIN	
		INPosting:
		BEGIN
			SELECT TOP 1 @CurrentID = SMINBatchID, @SMWorkCompletedID = SMWorkCompletedID, @BatchSeq = BatchSeq, @INCo = INCo, @IsReversingEntry = IsReversingEntry
			FROM dbo.SMINBatch
			WHERE SMCo = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId
			IF (@@ROWCOUNT = 1)
			BEGIN
				BEGIN TRAN
					SET @SeqErrMsg = 'Seq# ' + dbo.vfToString(@BatchSeq)
			
					EXEC @INTrans = dbo.bspHQTCNextTrans @tablename = 'bINDT', @co = @INCo, @mth = @BatchMth, @errmsg = @msg OUTPUT
			
					IF @INTrans = 0
					BEGIN
						SET @msg = @SeqErrMsg + ' - Unable to update IN Detail.'
						GOTO RollbackErrorFound
					END
				
					-- Insert distribution into INDT
					INSERT INTO dbo.INDT
					(
						INCo,
						Mth,
						INTrans,
						Loc,
						MatlGroup,
						Material,
						ActDate,
						PostedDate,
						[Source],
						TransType,
						GLCo,
						GLAcct,
						[Description],
						PostedUM,
						PostedUnits,
						PostedUnitCost,
						PostECM,
						PostedTotalCost,
						StkUM,
						StkUnits,
						StkUnitCost,
						StkECM,
						StkTotalCost,
						UnitPrice,
						PECM,
						TotalPrice,
						BatchId,
						SMCo,
						SMWorkOrder,
						SMScope
					)
					SELECT 
						INCo, 
						@BatchMth, 
						@INTrans, 
						INLocation, 
						MaterialGroup, 
						Material, 
						SaleDate, 
						@DatePosted, 
						'SM', 
						'AR Sale', 
						SMGLCo,				--INGLCo, Switched these to the SM Cost account
						SMCostGLAccount,	--InventoryGLAccount, 
						MaterialDescription,
						UM, 
						Quantity, 
						UnitCost, 
						CostECM, 
						TotalCost, 
						StockUM, 
						StockUnits, 
						StockUnitCost, 
						StockECM, 
						StockTotalCost, 
						UnitPrice, 
						PriceECM, 
						TotalPrice, 
						@BatchId,
						SMCo,
						WorkOrder,
						Scope
					FROM dbo.SMINBatch
					WHERE SMINBatchID = @CurrentID
					IF (@@ROWCOUNT <> 1)
					BEGIN
						SET @msg = @SeqErrMsg + ' - Unable to insert IN details Transaction.'
						GOTO RollbackErrorFound
					END
					
					IF (@IsReversingEntry = 0)
					BEGIN
						-- Update the work completed record with the trans info
						UPDATE dbo.vSMWorkCompleted
						SET CostCo = @INCo, CostMth = @BatchMth, CostTrans = @INTrans
						WHERE SMWorkCompletedID = @SMWorkCompletedID
					END

					-- Remove the transaction from the batch distribution table
					DELETE FROM dbo.SMINBatch WHERE SMINBatchID = @CurrentID
					IF (@@ROWCOUNT <> 1)
					BEGIN
						SET @msg = @SeqErrMsg + ' - Unable to remove SM IN batch sequence.'
						GOTO RollbackErrorFound
					END

				COMMIT TRAN
				
				GOTO INPosting
			END
		END
	END
	ELSE
	BEGIN
		DELETE FROM dbo.SMINBatch
		WHERE SMCo = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId
	END

	/*START JOB COST DETAIL RECORD UPDATE*/
	--GL POSTING
	EXEC @rcode = dbo.vspSMGLDistributionPost @SMCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @PostDate = @DatePosted, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode


	/*START JOB COST DETAIL RECORD UPDATE*/	
	EXEC @rcode = dbo.vspSMJobCostDetailInsert  @BatchCo=@SMCo,@BatchMth=@BatchMth,@BatchId = @BatchId, @errmsg=@msg OUTPUT
	IF @rcode <> 0
	BEGIN
			SET @msg = @SeqErrMsg + ' - Unable to update Job Cost Detail. ' + dbo.vfToString(@msg)
			RETURN @rcode
	END

	--Update the vSMDetailTransaction records as posted, delete work completed that was marked as deleted and update
	--the cost flags.
	EXEC @rcode = dbo.vspSMWorkCompletedPost @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @GLInterfaceLevel = @GLLvl, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	SELECT @BatchNotes = 'IN Interface set at: ' + @PostToIN + CHAR(13) + CHAR(10) +
		'GL Revenue Interface Level set at: ' + dbo.vfToString(@GLLvl) + CHAR(13) + CHAR(10)
	
	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @Notes = @BatchNotes, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SET @msg = NULL
	RETURN 0
	
RollbackErrorFound:
	--If an error is found then we need to properly handle the rollback
	--The assumption is if the transaction count = 1 then we are not in a nested
	--transaction and we can safely rollback. However, if the transaction count is greater than 1
	--then we are in a nested transaction and we need to make sure that the transaction count
	--when we entered the stored procedure matches the transaction count when we leave the stored procedure.
	--Then by returning 1 the rollback can be done from whatever sql executed this stored procedure.
	IF (@@TRANCOUNT = 1) ROLLBACK TRAN ELSE COMMIT TRAN

	RETURN 1
END
     
 


GO
GRANT EXECUTE ON  [dbo].[vspSMINBatchPost] TO [public]
GO
