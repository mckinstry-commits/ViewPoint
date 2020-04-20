SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 2/18/2011
-- Description:	SM batch validation for IN usage
-- Modified:  TRL TK-12770 added code to insert records to SMJobCostDistribution
--				  TRL TK-15053 added @JCTransType Parameter for vspSMJobCostDistributionInsert
--				JVH 4/3/13 TFS-38853 Updated to handle changes to vSMJobCostDistribution
-- =============================================
CREATE PROCEDURE [dbo].[vspSMINBatchValidation]
	(@SMCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Source bSource, @TableName varchar(10), @msg varchar(255) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @HQBatchDistributionID bigint
	DECLARE @SMINBatchID bigint, @SMWorkCompletedID bigint, @WorkOrder int, @WorkCompleted int, @Scope int, @IsReversingEntry bit, 
		@BatchSeq int, @SaleDate bDate, @CustomerGroup bGroup, @Customer bCustomer, @INCo bCompany, 
		@INLocation bLoc, @MaterialGroup bGroup, @Material bMatl, @UM bUM, @Quantity bUnits, 
		@UnitCost bUnitCost, @CostECM bECM, @TotalCost bDollar, @UnitPrice bUnitCost, @PriceECM bECM, 
		@TotalPrice bDollar, @SMGLCo bCompany, @INGLCo bCompany, @CostOfGoodsGLAccount bGLAcct, 
		@InventoryGLAccount bGLAcct, @SMCostGLAccount bGLAcct, @ServiceSalesGLAccount bGLAcct, @StockUM bUM, 
		@StockUnits bUnits, @StockUnitCost bUnitCost, @StockECM bECM, @StockTotalCost bDollar, 
		@ErrorText varchar(255), @APGLAccount bGLAcct, @ARGLAccount bGLAcct, 
		@TransDesc bTransDesc, @GLJournal bJrnl, @GLLvl varchar(50), @GLSumDesc varchar(60), @GLDetlDesc varchar(60),
		@SMGLDistributionID bigint, @SMGLEntryID bigint, @ValidationGLCo bCompany, @ValidationGLAcct bGLAcct, @SubType char(1), @SMGLDetailTransactionID bigint
		
	--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @Source = @Source, @TableName = @TableName, @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	SELECT @GLJournal = GLJrnl, @GLLvl = GLLvl, @GLSumDesc = dbo.vfToString(GLSumDesc), @GLDetlDesc = rtrim(dbo.vfToString(GLDetlDesc))
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo
	
	IF @GLJournal IS NULL AND @GLLvl <> 'NoUpdate'
	BEGIN
		SET @msg = 'GLJrnl may not be null in vSMCO'
		RETURN 1
	END
	
	--Capture all the GL Entries to delete before we delete the distribution records
	DECLARE @SMGLEntriesToDelete TABLE (SMGLEntryID bigint)
	
	INSERT @SMGLEntriesToDelete
	SELECT SMGLEntriesToDelete.SMGLEntryID
	FROM dbo.vSMGLDistribution
		CROSS APPLY (
			SELECT SMGLEntryID
			UNION
			SELECT ReversingSMGLEntryID
		) SMGLEntriesToDelete
	WHERE SMCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND SMGLEntriesToDelete.SMGLEntryID IS NOT NULL
	
	--Clear GL distributions
	DELETE dbo.vSMGLDistribution
	WHERE SMCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	
	--Clear GL Entries
	DELETE dbo.vSMGLEntry
	WHERE SMGLEntryID IN (SELECT SMGLEntryID FROM @SMGLEntriesToDelete)

	/*Clear records from SMJostCostDistribution*/
	DELETE dbo.vSMJobCostDistribution
	WHERE BatchCo = @SMCo AND BatchMth = @BatchMth AND BatchID = @BatchId	
	
	/*Clear records currently being created by job related work orders*/
	EXEC @rcode = dbo.vspSMWorkCompletedBatchClear @BatchCo = @SMCo, @BatchMonth = @BatchMth, @BatchId = @BatchId, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	-- GL Distributions table var
	DECLARE @SMGLDistributions TABLE (SMGLEntryID bigint, IsTransactionForSMDerivedAccount bit, GLCo bCompany, GLAccount bGLAcct, Amount bDollar, ActDate bDate, [Description] bTransDesc, SubType char(1) NULL)
	
	--Build the vSMDetailTransaction records and tie them to this batch
	EXEC @rcode = dbo.vspSMWorkCompletedValidate @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @HQBatchDistributionID = @HQBatchDistributionID, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	DECLARE vcSMINBatch CURSOR LOCAL FAST_FORWARD FOR
	SELECT
		SMINBatchID,
		BatchSeq,
		SMWorkCompletedID,
		WorkOrder,
		WorkCompleted,
		Scope,
		IsReversingEntry,
		SaleDate,
		INCo,
		INLocation,
		MaterialGroup,
		Material,
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
	FROM dbo.vSMINBatch
	WHERE 
		SMCo = @SMCo
		AND Mth = @BatchMth
		AND BatchId = @BatchId
		
	OPEN vcSMINBatch
	
vcSMINBatch_Start:
	FETCH NEXT FROM vcSMINBatch
	INTO
		@SMINBatchID,
		@BatchSeq,
		@SMWorkCompletedID,
		@WorkOrder,
		@WorkCompleted,
		@Scope,
		@IsReversingEntry,
		@SaleDate,
		@INCo,
		@INLocation,
		@MaterialGroup,
		@Material,
		@UM,
		@Quantity,
		@UnitCost,
		@CostECM,
		@TotalCost,
		@UnitPrice,
		@PriceECM,
		@TotalPrice,
		@SMGLCo,
		@INGLCo,
		@CostOfGoodsGLAccount,
		@InventoryGLAccount,
		@SMCostGLAccount,
		@ServiceSalesGLAccount,
		@StockUM,
		@StockUnits,
		@StockUnitCost,
		@StockECM,
		@StockTotalCost
		
	IF @@FETCH_STATUS <> -1 
	BEGIN
		SET @ErrorText = 'Seq# ' + dbo.vfToString(@BatchSeq) + ' '
		
-- Validation of fields
		-- Validate Scope
		EXEC @rcode = dbo.vspSMWorkOrderScopeVal @SMCo, @WorkOrder, @Scope, 'Y'
		IF (@rcode <> 0)
		BEGIN
			SET @ErrorText = 'Invalid Scope.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Sale Date is required
		IF @SaleDate IS NULL
		BEGIN
			SET @ErrorText = 'Invalid sale date.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- INCo validation
		EXEC @rcode = dbo.vspINCompanyVal @INCo, NULL, NULL, NULL, @msg OUTPUT
		IF (@rcode <> 0 )
		BEGIN
			SET @ErrorText = 'Invalid inventory company.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- IN Location validation
		EXEC @rcode = dbo.bspINLocVal @INCo, @INLocation, 'Y', NULL, NULL, @msg OUTPUT
		IF (@rcode <> 0 )
		BEGIN
			SET @ErrorText = 'Invalid inventory location.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Material Group validation
		EXEC @rcode = dbo.bspHQGroupVal @MaterialGroup, @msg OUTPUT
		IF (@rcode <> 0 )
		BEGIN
			SET @ErrorText = 'Invalid material group.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Material validation
		IF (NOT EXISTS(SELECT 1 FROM INMT WHERE INCo = @INCo AND Loc = @INLocation AND MatlGroup = @MaterialGroup AND Material = @Material))
		BEGIN
			SET @ErrorText = 'Invalid Material.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- UM Validation
		EXEC @rcode = dbo.vspSMWorkCompletedPartUMVal 0, @INCo, @INLocation, @MaterialGroup, @Material, @UM, @msg OUTPUT
		IF (@rcode <> 0) 
		BEGIN
			SET @ErrorText = 'Invalid UM.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Cost ECM validation
		IF (@CostECM NOT IN ('E', 'C', 'M'))
		BEGIN
			SET @ErrorText = 'Invalid cost ECM.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Price ECM validation
		IF (@PriceECM NOT IN ('E', 'C', 'M'))
		BEGIN
			SET @ErrorText = 'Invalid price ECM.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Validate SMGLCo
		EXEC @rcode = dbo.bspGLCompanyVal @SMGLCo, @msg OUTPUT
		IF (@rcode <> 0) 
		BEGIN
			SET @ErrorText = 'Invalid SM GL Company.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Validate INGLCo
		EXEC @rcode = dbo.bspGLCompanyVal @INGLCo, @msg OUTPUT
		IF (@rcode <> 0) 
		BEGIN
			SET @ErrorText = 'Invalid IN GL Company.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		-- Validate Inventory GL Account
		IF (@InventoryGLAccount IS NULL) 
		BEGIN
			SET @ErrorText = 'Missing Inventory GL Account.'
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		IF (@IsReversingEntry = 0)
		BEGIN
			-- Validate Cost of Goods GL Account
			IF (@CostOfGoodsGLAccount IS NULL) 
			BEGIN
				SET @ErrorText = 'Missing Cost of Goods GL Account.'
				EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
				IF (@rcode <> 0) GOTO Cursor_Exit
				GOTO vcSMINBatch_Start
			END
			
			-- Validate Service Sales GL Account
			IF (@ServiceSalesGLAccount IS NULL) 
			BEGIN
				SET @ErrorText = 'Missing Service Sales GL Account.'
				EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
				IF (@rcode <> 0) GOTO Cursor_Exit
				GOTO vcSMINBatch_Start
			END
			
			-- Validate SM Cost GL Account
			IF (@SMCostGLAccount IS NULL) 
			BEGIN
				SET @ErrorText = 'Missing SM Cost GL Account.'
				EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
				IF (@rcode <> 0) GOTO Cursor_Exit
				GOTO vcSMINBatch_Start
			END
		END
		
		IF @GLJournal IS NOT NULL
		BEGIN
			-- Validate the journal
			EXEC @rcode = dbo.bspGLJrnlVal @SMGLCo, @GLJournal, @msg OUTPUT
			IF (@rcode <> 0)
			BEGIN
				SET @ErrorText = 'Journal ' + @GLJournal + ' is invalid for GLCo ' + dbo.vfToString(@SMGLCo)
				EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
				IF (@rcode <> 0) GOTO Cursor_Exit
				GOTO vcSMINBatch_Start
			END		
		END
		
		-- Make sure the month is not closed for SMGLCo
		IF EXISTS(SELECT 1 FROM dbo.bGLCO WHERE GLCo = @SMGLCo AND @BatchMth <= LastMthSubClsd)
		BEGIN
			SET @ErrorText = 'Month is closed in GL Company ' + dbo.vfToString(@SMGLCo)
			EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
			IF (@rcode <> 0) GOTO Cursor_Exit
			GOTO vcSMINBatch_Start
		END
		
		--Inter company accounting needs to be handled
		IF (@SMGLCo <> @INGLCo)
		BEGIN
			IF @GLJournal IS NOT NULL
			BEGIN
				-- Check to see if the journal is valid for the INGLCo
				EXEC @rcode = dbo.bspGLJrnlVal @INGLCo, @GLJournal, @msg OUTPUT
				IF (@rcode <> 0)
				BEGIN
					SET @ErrorText = 'Journal ' + @GLJournal + ' is invalid for GLCo ' + dbo.vfToString(@INGLCo)
					EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
					IF (@rcode <> 0) GOTO Cursor_Exit
					GOTO vcSMINBatch_Start
				END
			END
		
			-- Make sure the month is not closed for INGLCo
			IF EXISTS(SELECT 1 FROM dbo.bGLCO WHERE GLCo = @INGLCo AND @BatchMth <= LastMthSubClsd)
			BEGIN
				SET @ErrorText = 'Month is closed in GL Company ' + dbo.vfToString(@INGLCo)
				EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
				IF (@rcode <> 0) GOTO Cursor_Exit
				GOTO vcSMINBatch_Start
			END
			
			SELECT @ARGLAccount = ARGLAcct, @APGLAccount = APGLAcct
			FROM dbo.bGLIA
			WHERE ARGLCo = @INGLCo AND APGLCo = @SMGLCo
			
			IF (@ARGLAccount IS NULL OR @APGLAccount IS NULL)
			BEGIN
				SET @ErrorText = @ErrorText + '- Missing cross company gl account(s) !'
				EXEC @rcode = dbo.bspHQBEInsert @SMCo, @BatchMth, @BatchId, @ErrorText, @msg OUTPUT
				IF @rcode <> 0 GOTO Cursor_Exit
				GOTO vcSMINBatch_Start
			END
		END
		
		SELECT @SMGLDistributionID = SMGLDistributionID
		FROM dbo.vSMGLDistribution
		WHERE SMCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND SMWorkCompletedID = @SMWorkCompletedID
		
		IF @@rowcount = 0
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID)
			BEGIN
				INSERT dbo.vSMWorkCompletedGL (SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
				VALUES (@SMWorkCompletedID, @SMCo, 0)
			END

			INSERT dbo.vSMGLDistribution (SMWorkCompletedID, SMCo, BatchMonth, BatchId, CostOrRevenue, IsAccountTransfer)
			VALUES (@SMWorkCompletedID, @SMCo, @BatchMth, @BatchId, 'C', 0)
			
			SET @SMGLDistributionID = SCOPE_IDENTITY()
		END
		
		IF (@IsReversingEntry = 0)
		BEGIN
			SELECT @TransDesc = @GLDetlDesc,
				@TransDesc = REPLACE(@TransDesc, 'SM Company', dbo.vfToString(@SMCo)),
				@TransDesc = REPLACE(@TransDesc, 'Work Order', dbo.vfToString(@WorkOrder)),
				@TransDesc = REPLACE(@TransDesc, 'Scope', dbo.vfToString((SELECT Scope FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID))),
				@TransDesc = REPLACE(@TransDesc, 'Line Type', '4'),  --4 is the Material Line type
				@TransDesc = REPLACE(@TransDesc, 'Line Sequence', dbo.vfToString((SELECT WorkCompleted FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID)))

			INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal)
			VALUES (@SMWorkCompletedID, @GLJournal)
			
			SET @SMGLEntryID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET SMGLEntryID = @SMGLEntryID
			WHERE SMGLDistributionID = @SMGLDistributionID

			DELETE @SMGLDistributions
			
			-- Insert Cross company accounting entries if needed
			IF (@SMGLCo <> @INGLCo)
			BEGIN
				--Credit cross company AP Account
				INSERT INTO @SMGLDistributions
				VALUES (@SMGLEntryID, 0, @SMGLCo, @APGLAccount, @TotalPrice, @SaleDate, @TransDesc, NULL)

				--Debit cross company AR Account
				INSERT INTO @SMGLDistributions
				VALUES (@SMGLEntryID, 0, @INGLCo, @ARGLAccount, -(@TotalPrice), @SaleDate, @TransDesc, NULL)
			END

			-- Insert normal GL entries (values such as cost or totals are already reversed for INDT)
			-- Insert the Inventory GL Credit
			INSERT INTO @SMGLDistributions
			VALUES(@SMGLEntryID, 0, @INGLCo, @InventoryGLAccount, @TotalCost, @SaleDate, @TransDesc, 'I')
			
			-- Insert the Cost of Goods GL Debit
			INSERT INTO @SMGLDistributions
			VALUES (@SMGLEntryID, 0, @INGLCo, @CostOfGoodsGLAccount, -(@TotalCost), @SaleDate, @TransDesc, 'I')
			
			-- Insert the Sales to Service Management GL Account Credit
			INSERT INTO @SMGLDistributions 
			VALUES (@SMGLEntryID, 0, @INGLCo, @ServiceSalesGLAccount, @TotalPrice, @SaleDate, @TransDesc, 'I')
			
			-- Insert the SM Cost GL Account Debit
			INSERT INTO @SMGLDistributions 
			VALUES (@SMGLEntryID, 1, @SMGLCo, @SMCostGLAccount, -(@TotalPrice), @SaleDate, @TransDesc, 'S')
			
			SELECT @ValidationGLCo = @SMGLCo, @ValidationGLAcct = NULL

			GLAccountValidationLoop:
			BEGIN
				SELECT TOP 1 @ValidationGLAcct = GLAccount, @SubType = SubType
				FROM @SMGLDistributions
				WHERE GLCo = @ValidationGLCo AND (@ValidationGLAcct IS NULL OR GLAccount > @ValidationGLAcct)
				ORDER BY GLAccount
				IF @@rowcount = 1
				BEGIN
					EXEC @rcode = dbo.bspGLACfPostable @glco = @ValidationGLCo, @glacct = @ValidationGLAcct, @chksubtype = @SubType, @msg = @msg OUTPUT
					IF @rcode <> 0
					BEGIN
						SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
						EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
						IF @rcode <> 0 GOTO Cursor_Exit
						GOTO vcSMINBatch_Start
					END
					
					GOTO GLAccountValidationLoop
				END
				
				IF @ValidationGLCo <> @INGLCo
				BEGIN
					SELECT @ValidationGLCo = @INGLCo, @ValidationGLAcct = NULL
					GOTO GLAccountValidationLoop
				END
			END
			
			-- make sure debits and credits balance
			IF EXISTS(SELECT 1 
						FROM @SMGLDistributions
						GROUP BY GLCo
						HAVING ISNULL(SUM(Amount), 0) <> 0)
			BEGIN
				SET @ErrorText = @ErrorText + '- GL entries dont balance!'
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO Cursor_Exit
				GOTO vcSMINBatch_Start
			END
			
			INSERT INTO dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT @SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description]
			FROM @SMGLDistributions
			ORDER BY IsTransactionForSMDerivedAccount
			
			--The last record entered should be the offset account since it was the only record that has IsTransactionForSMDerivedAccount = 1 and
			--we ordered by IsTransactionForSMDerivedAccount
			SET @SMGLDetailTransactionID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET SMGLDetailTransactionID = @SMGLDetailTransactionID
			WHERE SMGLDistributionID = @SMGLDistributionID
		END
		ELSE
		BEGIN
			INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal)
			SELECT @SMWorkCompletedID, ISNULL((SELECT Journal FROM dbo.vSMWorkCompletedGL INNER JOIN dbo.vSMGLEntry ON vSMWorkCompletedGL.CostGLEntryID = vSMGLEntry.SMGLEntryID WHERE vSMWorkCompletedGL.SMWorkCompletedID = @SMWorkCompletedID), @GLJournal)
			
			SET @SMGLEntryID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET ReversingSMGLEntryID = @SMGLEntryID
			WHERE SMGLDistributionID = @SMGLDistributionID
		
			--Reversing data comes from vfSMBuildReversingTransactions
			INSERT INTO dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT @SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description]
			FROM dbo.vfSMBuildReversingTransactions(@SMWorkCompletedID)
			WHERE IsTransactionForSMDerivedAccount IS NOT NULL
		END
		
		/*START SM JOB COST DISTRIBUTIONS*/
		--IsDeleleted is used here until this procedure is refacted and vSMINBatch has the add BratchTransType column added
		DECLARE @IsDeleted bit 
		select @IsDeleted=IsDeleted from dbo.vSMWorkCompleted WHERE SMWorkCompletedID=@SMWorkCompletedID
		IF @IsReversingEntry = 0 or  @IsDeleted = 1 --or @BatchTransType = 'D'
		BEGIN
				exec @rcode = dbo.vspSMJobCostDistributionInsert @SMWorkCompletedID=@SMWorkCompletedID, @BatchCo=@SMCo,@BatchMth=@BatchMth,@BatchId = @BatchId, @BatchSeq = @BatchSeq, @JCTransType='IN',@errmsg = @msg OUTPUT
				IF @rcode <> 0 
				BEGIN
					SET @ErrorText = @ErrorText + ' - ' + dbo.vfToString(@msg)
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO Cursor_Exit
					GOTO vcSMINBatch_Start
				END
		END
		/*END SM JOB COST DISTRIBUTIONS*/

		GOTO vcSMINBatch_Start
	END
	SET @rcode = 0 -- Reset the rcode if all has executed properly
	
Cursor_Exit:
	CLOSE vcSMINBatch
	DEALLOCATE vcSMINBatch
	
	If (@rcode <> 0) GOTO Error_Exit -- rcode will be 1 if there was an error writing to HQBE
	
	-- Check for batch errors and set the batch control status
	SELECT TOP 1 @msg = ErrorText FROM dbo.HQBE WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId ORDER BY Seq ASC
	IF (@@ROWCOUNT > 0)
	BEGIN
		GOTO Error_Exit
	END
	
	--Insert our control records so that the months cannot be closed
	INSERT INTO dbo.bHQCC (Co, Mth, BatchId, GLCo)
	SELECT @SMCo, @BatchMth, @BatchId, GLCo
	FROM dbo.vSMGLDistribution
		INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLDistribution.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
	WHERE vSMGLDistribution.SMCo = @SMCo AND vSMGLDistribution.BatchMonth = @BatchMth AND vSMGLDistribution.BatchId = @BatchId
	GROUP BY GLCo
	
	-- Update HQBC with Ready for posting status
	UPDATE dbo.bHQBC 
	SET [Status] = 3
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId

	RETURN 0


Error_Exit:

	-- Update HQBC with Errors found status
	UPDATE dbo.bHQBC 
	SET [Status] = 2
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId
	
	RETURN 1
END


GO
GRANT EXECUTE ON  [dbo].[vspSMINBatchValidation] TO [public]
GO
