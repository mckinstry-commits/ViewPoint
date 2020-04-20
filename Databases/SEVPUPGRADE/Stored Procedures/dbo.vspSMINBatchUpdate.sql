SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 2/14/2010
-- Description:	Handles receiving against Inventory for SM part work completed part records.
-- VERY IMPORTANT!!! - It is important to execute the stored procedure using input/output parameters
-- this sproc will get called twice from code. The second time the record is executed the work completed
-- record will not be available when the BatchTransType is 'D' (delete). We rely on the first time the sproc
-- was executed to retrieve the PostedMth and the Trans.
--
-- Modified:
--				JB 12/12/12 Not only an awesome date...but refactored this sproc for separation of Purhcase/inventory.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMINBatchUpdate]
(
	@SMCo bCompany, 
	@BatchMth bMonth, 
	@BatchId int,
	@BatchTransType char(1),
	@WorkOrder int, 
	@WorkCompleted int,
	@Scope int,
	@SaleDate bDate,
	@INCo bCompany,
	@INLocation bLoc, 
	@MaterialGroup bGroup,
	@Material bMatl,
	@UM bUM,
	@Quantity bUnits,
	@SMPartUnitCost bUnitCost,		-- This is the IN Unit Price
	@SMPartCostECM bECM,			-- This is the IN Price ECM
	@SMPartTotalCost bDollar,		-- This is the IN Total Price
	@SMGLCo bCompany,
	@SMCostGLAccount bGLAcct,
	@SMWorkCompletedID bigint = NULL OUTPUT,
	@msg varchar(255) = NULL OUTPUT
)
   		
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @UnitCost bUnitCost, @CostECM bECM, @TotalCost bDollar, 
			@UnitPrice bUnitCost, @PriceECM bECM, @TotalPrice bDollar, 
			@rcode int,
			@ReversingGLCo bCompany, @ReversingGLAccount bGLAcct,
			@TransCo bCompany, @TransMth bMonth, @Trans bTrans, @CostDetailID bigint
	
	-- Define constant values & convert SM Part Cost variable to IN Price variables
	SELECT @UnitPrice = @SMPartUnitCost, @PriceECM = @SMPartCostECM, @TotalPrice = @SMPartTotalCost

  	SET @msg = 
  		CASE 
  			WHEN @SMCo IS NULL THEN 'Missing SM Company.'
			WHEN @BatchMth IS NULL THEN 'Missing Batch Month.'
			WHEN @BatchId IS NULL THEN 'Missing Batch ID.'
			WHEN @BatchTransType IS NULL THEN 'Missing Batch Transaction Type.'
			WHEN @WorkOrder IS NULL THEN 'Missing Work Order.'
			WHEN @WorkCompleted IS NULL THEN 'Missing Work Completed.'
			WHEN @Scope IS NULL THEN 'Missing Scope.'
			WHEN @SaleDate IS NULL THEN 'Missing Sale Date.'
			WHEN @INCo IS NULL THEN 'Missing IN Company.'
			WHEN @INLocation IS NULL THEN 'Missing IN Location.'
			WHEN @MaterialGroup IS NULL THEN 'Missing Material Group.'
			WHEN @Material IS NULL THEN 'Missing Material.'
			WHEN @UM IS NULL THEN 'Missing UM.'
			WHEN @Quantity IS NULL THEN 'Missing Quantity.'
			WHEN @SMPartUnitCost IS NULL THEN 'Missing Unit Cost.'
			WHEN @SMPartCostECM IS NULL THEN 'Missing Cost ECM.'
			WHEN @SMPartTotalCost IS NULL THEN 'Missing Total Cost.'
			WHEN @UnitPrice IS NULL THEN 'Missing Unit Price.'
			WHEN @PriceECM IS NULL THEN 'Missing Price ECM.'
			WHEN @TotalPrice IS NULL THEN 'Missing Total Price.'
			WHEN @SMGLCo IS NULL THEN 'Missing GL Company.'
			WHEN @SMCostGLAccount IS NULL THEN 'Missing SM Cost GL Account.'
		END
	
	IF @msg IS NOT NULL
	BEGIN	
		RETURN 1
	END

	SELECT @TransCo = CostCo, @TransMth = CostMth, @Trans = CostTrans, @SMWorkCompletedID = SMWorkCompletedID, @CostDetailID = CostDetailID
	FROM dbo.vSMWorkCompleted
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND [Type] = 4 AND WorkCompleted = @WorkCompleted
	
	--For add records the work completed record won't exist so we use -1 for our test run.
	IF @SMWorkCompletedID IS NULL SET @SMWorkCompletedID = -1
	
	IF @CostDetailID IS NULL
	BEGIN
		EXEC @rcode = dbo.vspHQDetailCreate @Source = 'SM Inv', @HQDetailID = @CostDetailID OUTPUT, @msg = @msg OUTPUT
		IF @rcode <> 0 RETURN 1
		
		UPDATE dbo.vSMWorkCompleted
		SET CostDetailID = @CostDetailID
		WHERE SMWorkCompletedID = @SMWorkCompletedID
	END
	
	--Always make sure the trans type is up to date because the user may have first modified
	--the work completed and it got added to the batch but then decided to delete the record.
	UPDATE dbo.vHQBatchLine
	SET BatchTransType = @BatchTransType
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId AND HQDetailID = @CostDetailID
	IF @@rowcount = 0
	BEGIN
		INSERT dbo.vHQBatchLine (Co, Mth, BatchId, HQDetailID, BatchTransType)
		VALUES (@SMCo, @BatchMth, @BatchId, @CostDetailID, @BatchTransType)
	END
	
	DECLARE @BatchSeq int, @NextBatchSeq int, @IsCorrectBatch bit, @BatchRecordAlreadyExist bit
	
	SET @BatchRecordAlreadyExist = 0
	
	--If we have already made changes to the record in this batch then we make updates to the record we added.
	SELECT @BatchRecordAlreadyExist = 1, @IsCorrectBatch = CASE WHEN @SMCo = SMCo AND @BatchMth = Mth AND @BatchId = BatchId THEN 1 ELSE 0 END
	FROM dbo.SMINBatch
	WHERE SMWorkCompletedID = @SMWorkCompletedID AND IsReversingEntry = 0
	
	IF (@IsCorrectBatch = 0)
	BEGIN
		SET @msg = 'This record is being received against a different batch. You cannot make changes to it until the other changes have been completed.'
		RETURN 1
	END

	SELECT @NextBatchSeq = ISNULL(MAX(BatchSeq), 0) + 1
	FROM dbo.SMINBatch 
	WHERE SMCo = @SMCo and Mth = @BatchMth and BatchId = @BatchId 
	
	--If the batch has been validated which it should be every time a record is added
	--then we should pull the batch back to the non validated state so we can add more records
	UPDATE dbo.HQBC
	SET [Status] = 0
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId AND [Status] = 3

	--If we have the TransCo, TransMth and the Trans then we have made changes in a previous batch
	IF (@TransCo IS NOT NULL AND @TransMth IS NOT NULL AND @Trans IS NOT NULL)
	BEGIN		
		-- Because we have made changes in a previous batch we need to add a correcting entry
		IF (@BatchRecordAlreadyExist = 0)
		BEGIN
			--Use the WorkCompletedGL because INDT doesn't get updated with the GL Account after wip transfer.
			SELECT @ReversingGLCo = vSMGLDetailTransaction.GLCo, @ReversingGLAccount = vSMGLDetailTransaction.GLAccount
			FROM dbo.vSMWorkCompletedGL
				INNER JOIN dbo.vSMGLDetailTransaction ON vSMWorkCompletedGL.CostGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
			WHERE SMWorkCompletedID = @SMWorkCompletedID
			
			--Add the reversing entry
			INSERT dbo.SMINBatch 
			(
				SMCo, 
				Mth, 
				BatchId, 
				BatchSeq, 
				WorkOrder, 
				WorkCompleted,
				SMWorkCompletedID,
				Scope,
				IsReversingEntry,
				SaleDate,
				INCo, 
				INLocation, 
				MaterialGroup, 
				Material,
				MaterialDescription,
				UM, 
				Quantity, 
				UnitCost, 
				CostECM, 
				TotalCost, 
				UnitPrice, 
				PriceECM, 
				TotalPrice,
				SMGLCo,
				INGLCo,
				InventoryGLAccount,
				StockUM,
				StockUnits,
				StockUnitCost,
				StockECM,
				StockTotalCost
			)
			SELECT 
				@SMCo,
				@BatchMth,
				@BatchId,
				@NextBatchSeq,
				@WorkOrder,
				@WorkCompleted,
				@SMWorkCompletedID,
				INDT.SMScope,
				1,
				INDT.ActDate,
				INDT.INCo,
				INDT.Loc,
				INDT.MatlGroup,
				INDT.Material,
				INDT.[Description],
				INDT.PostedUM,
				-(INDT.PostedUnits), -- Reverse
				INDT.PostedUnitCost,
				INDT.PostECM,
				-(INDT.PostedTotalCost), -- Reverse
				INDT.UnitPrice,
				INDT.PECM,
				-(INDT.TotalPrice),  -- Reverse
				@SMGLCo,
				@ReversingGLCo,
				@ReversingGLAccount,
				INDT.StkUM,
				-(INDT.StkUnits),  -- Reverse
				INDT.StkUnitCost,
				INDT.StkECM,
				-(INDT.StkTotalCost) -- Reverse
			FROM dbo.INDT
			WHERE INDT.INCo = @TransCo AND INDT.Mth = @TransMth AND INDT.INTrans = @Trans

			SET @NextBatchSeq = @NextBatchSeq + 1
		END
	END
	
	IF (@BatchTransType IN ('A','C'))
	BEGIN
		DECLARE @MaterialCategory varchar(10), @MaterialStdUM bUM, @MaterialDescription bItemDesc,
				@INGLCo bCompany, @InventoryGLAccount bGLAcct, @CostOfGoodsGLAccount bGLAcct, 
				@ServiceSalesGLAccount bGLAcct, @MaterialConversion bUnits, @StockUM bUM, 
				@StockUnits bUnits, @StockUnitCost bUnitCost, @StockECM bECM, @StockTotalCost bDollar, 
				@CostMethod int
	
		-- Get some needed material info
		SELECT @MaterialCategory = Category, @MaterialStdUM = StdUM, @MaterialDescription = [Description]
		FROM HQMT WHERE MatlGroup = @MaterialGroup AND Material = @Material
		
		-- Get GL Accounts & Overrides
		SELECT @INGLCo = GLCo FROM INCO WHERE INCo = @INCo
		
		SELECT @InventoryGLAccount = InvGLAcct, @CostOfGoodsGLAccount = CostGLAcct, @ServiceSalesGLAccount = ServiceSalesGLAcct
		FROM INLM WHERE INCo = @INCo AND Loc = @INLocation

		SELECT 
			@InventoryGLAccount = ISNULL(InvGLAcct, @InventoryGLAccount),
			@CostOfGoodsGLAccount = ISNULL(CostGLAcct, @CostOfGoodsGLAccount)
		FROM INLO
		WHERE INCo = @INCo AND Loc = @INLocation AND MatlGroup = @MaterialGroup AND Category = @MaterialCategory
		
		-- Get the Inventory Cost information
		EXEC @rcode = dbo.vspSMINMaterialCostGet @INCo, @INLocation, @MaterialGroup, @Material, @UM, @Quantity, NULL, @UnitCost OUTPUT, @CostECM OUTPUT, NULL, @TotalCost OUTPUT, @msg OUTPUT
		IF (@rcode <> 0) RETURN @rcode
		
		-- Determine the Stock Units
		IF (@UM <> @MaterialStdUM)
		BEGIN
			-- Convert the quantity to a quantity in the standard UM.
			EXEC @rcode = dbo.vspSMInventoryConvertQuantity @INCo, @INLocation, @MaterialGroup, @Material, @UM, @Quantity, @MaterialStdUM, @StockUnits OUTPUT, @msg OUTPUT
			IF (@rcode <> 0) RETURN @rcode
		END
		ELSE
		BEGIN
			-- The quantity is already in the standard UM, just assign it to the stocked quantity.
			SELECT @StockUnits = @Quantity
		END
		
		SET @StockTotalCost = @TotalCost
		SET @StockUnitCost = @StockTotalCost / @StockUnits
		SET @StockECM = 'E'
		
		--We only add a record to the batch the first time we make changes to the record
		--within our batch. The next time and every time after we will update the record we added.
		IF (@BatchRecordAlreadyExist = 0)
		BEGIN
		
			INSERT INTO dbo.SMINBatch
			(                  
				SMCo,
				Mth,
				BatchId,
				BatchSeq,
				WorkOrder,
				WorkCompleted,
				SMWorkCompletedID,
				Scope,
				IsReversingEntry,
				SaleDate,
				INCo,
				INLocation,
				MaterialGroup,
				Material,
				MaterialDescription,
				UM,
				Quantity,
				UnitCost,
				CostECM,
				TotalCost,
				UnitPrice,
				PriceECM,
				TotalPrice,
				SMGLCo,
				INGLCo,
				CostOfGoodsGLAccount,
				InventoryGLAccount,
				SMCostGLAccount,
				ServiceSalesGLAccount,
				StockUM,
				StockUnits,
				StockUnitCost,
				StockECM,
				StockTotalCost
			)
			VALUES
			(
				@SMCo,
				@BatchMth,
				@BatchId,
				@NextBatchSeq,
				@WorkOrder,
				@WorkCompleted,
				@SMWorkCompletedID,
				@Scope,
				0,
				@SaleDate,
				@INCo,
				@INLocation,
				@MaterialGroup,
				@Material,
				@MaterialDescription,
				@UM,
				-(@Quantity), -- Reverse
				@UnitCost,
				@CostECM,
				-(@TotalCost), -- Reverse
				@UnitPrice,
				@PriceECM,
				-(@TotalPrice), -- Reverse
				@SMGLCo,
				@INGLCo,
				@CostOfGoodsGLAccount,
				@InventoryGLAccount,
				@SMCostGLAccount,
				@ServiceSalesGLAccount,
				@MaterialStdUM,
				-(@StockUnits), -- Reverse
				@StockUnitCost,
				@StockECM,
				-(@StockTotalCost) -- Reverse
			)			
		END
		ELSE
		BEGIN
			
			UPDATE dbo.SMINBatch
			SET
				WorkOrder = @WorkOrder,
				WorkCompleted = @WorkCompleted,
				Scope = @Scope,
				SaleDate = @SaleDate,
				INCo = @INCo,
				INLocation = @INLocation,
				MaterialGroup = @MaterialGroup,
				Material = @Material,
				MaterialDescription = @MaterialDescription,
				UM = @UM,
				Quantity = -(@Quantity), -- Reverse
				UnitCost = @UnitCost,
				CostECM = @CostECM,
				TotalCost = -(@TotalCost), -- Reverse
				UnitPrice = @UnitPrice,
				PriceECM = @PriceECM,
				TotalPrice = -(@TotalPrice), -- Reverse
				SMGLCo = @SMGLCo,
				INGLCo = @INGLCo,
				CostOfGoodsGLAccount = @CostOfGoodsGLAccount,
				InventoryGLAccount = @InventoryGLAccount,
				SMCostGLAccount = @SMCostGLAccount,
				ServiceSalesGLAccount = @ServiceSalesGLAccount,
				StockUM = @MaterialStdUM,
				StockUnits = -(@StockUnits), -- Reverse
				StockUnitCost = @StockUnitCost,
				StockECM = @StockECM,
				StockTotalCost = -(@StockTotalCost) -- Reverse
			WHERE
				SMWorkCompletedID = @SMWorkCompletedID 
				AND IsReversingEntry = 0
		END
	END
	ELSE IF (@BatchTransType = 'D')
	BEGIN
		--At this point we have already added the reversing entry if needed.
		
		--If we either added or made a change to a record then we will want to remove the added/changed entry
		IF (@BatchRecordAlreadyExist = 1)
		BEGIN
			DELETE FROM dbo.SMINBatch
			WHERE SMWorkCompletedID = @SMWorkCompletedID 
			AND IsReversingEntry = 0
		END
	END
END



GO
GRANT EXECUTE ON  [dbo].[vspSMINBatchUpdate] TO [public]
GO
