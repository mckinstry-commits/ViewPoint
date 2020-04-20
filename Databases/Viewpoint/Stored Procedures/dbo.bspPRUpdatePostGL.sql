SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspPRUpdatePostGL]
/***********************************************************
* CREATED: GG 07/10/98
* MODIFIED: GG 10/14/98
*			EN 6/06/01 - issue #11553 - enhancement to interface hours to GL memo acccounts
*           EN 7/17/01 - issue #14014
*			EN 10/9/02 - issue 18877 change double quotes to single
*			GG 01/31/03 - #19636 - update bPRGL old amts even if no change in total
*			GG 10/17/06 - #120831 use local fast_forward cursors
*			GG 04/18/08 - #127804 - add order by following grouping
*			JayR 10/16/2012 TK-16099  Fix overlapping variables
* USAGE:
* Called from bspPRUpdatePost to perform updates to
* GL, CM, PR Payment History, and Employee Accums.
*
*
* INPUT PARAMETERS
*   @prco   		PR Company
*   @prgroup  		PR Group to validate
*   @prenddate		Pay Period Ending Date
*   @postdate		Posting Date used for transaction detail
*   @status		Pay Period status 0 = open, 1 = closed
*
* OUTPUT PARAMETERS
*   @errmsg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/

(@prco bCompany, @prgroup bGroup, @prenddate bDate, @postdate bDate,
 @status tinyint, @errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @jrnl bJrnl, @glinterface bYN, @batchmth bMonth, @gldesc bTransDesc, @a bDesc,
   @openGL tinyint, @Mth bMonth, @glco bCompany, @glacct bGLAcct, @amt bDollar, @oldamt bDollar,
   @batchid int, @glref bGLRef, @gltrans int, @hrs bDollar, @oldhrs bDollar
   
   select @rcode = 0
   
   -- get PR Company info
   select @jrnl = Jrnl, @glinterface = GLInterface
   from bPRCO where PRCo = @prco
   if @@rowcount = 0
   	begin
       	select @errmsg = 'Invalid PR Company!', @rcode = 1
       	goto bspexit
       	end
   
   
	BEGIN TRY
		BEGIN TRAN
		
		;WITH WorkCompletedToUpdate
		AS
		(
			--This will retrieve reversing and correcting entries.
			SELECT vSMDetailTransaction.*
			FROM dbo.vPRLedgerUpdateDistribution
				INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
			WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C'
		)
		UPDATE vSMWorkCompletedLabor
		--If a correcting entry wasn't created like in the case that the time card was deleted then query will return null and in that case the actual amount should be updated to 0
		SET ActualCost = ISNULL((SELECT Amount FROM WorkCompletedToUpdate WHERE SMWorkCompletedID = vSMWorkCompletedLabor.SMWorkCompletedID AND IsReversing = 0), 0)
		FROM dbo.vSMWorkCompletedLabor
		WHERE SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM WorkCompletedToUpdate)

		--Update the work completed on actual cost job work orders so that the actual cost and price match
		;WITH WorkCompletedToUpdate
		AS
		(
			--This will retrieve reversing and correcting entries.
			SELECT vSMDetailTransaction.*
			FROM dbo.vPRLedgerUpdateDistribution
				INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
				INNER JOIN dbo.vSMWorkCompleted ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
				INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
			WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C' AND vSMWorkOrder.Job IS NOT NULL AND vSMWorkOrder.CostingMethod = 'Cost'
		)
		UPDATE SMWorkCompleted
		SET PriceQuantity = CASE WHEN PriceQuantity = 0 THEN NULL ELSE PriceQuantity END,
			PriceRate = ActualCost / CASE WHEN PriceQuantity = 0 THEN NULL ELSE PriceQuantity END,
			PriceTotal = ActualCost
		WHERE SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM WorkCompletedToUpdate)

		--Update the cost captured fields.
		UPDATE vSMWorkCompleted
		SET InitialCostsCaptured = 1, CostsCaptured = 1
		FROM dbo.vPRLedgerUpdateDistribution
			INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
			INNER JOIN dbo.vSMWorkCompleted ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C'
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
   		select @errmsg = 'SM ActualCost failed: '+ ERROR_MESSAGE(), @rcode = 1
   		goto bspexit
	END CATCH
   
   -- update GL
   if @glinterface = 'Y'
   	begin
       select @batchmth = null
   
       -- get Group description
       select @gldesc = 'PR Group:' + convert(varchar(3),@prgroup)
       select @a = Description from bPRGR where PRCo = @prco and PRGroup = @prgroup
       select @gldesc = @gldesc + ' ' + @a
       
		DECLARE @SMGLEntry TABLE (SMGLEntryID bigint NOT NULL, SMWorkCompletedID bigint NOT NULL)

		BEGIN TRY
			BEGIN TRAN
			
			-- Make sure the vSMWorkCompletedGL exists.
			INSERT dbo.vSMWorkCompletedGL (SMCo, SMWorkCompletedID, IsMiscellaneousLineType)
			SELECT DISTINCT vSMWorkCompleted.SMCo, vSMWorkCompleted.SMWorkCompletedID, 0 IsMiscellaneousLineType
			FROM dbo.vPRLedgerUpdateDistribution
				INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
				INNER JOIN dbo.vSMWorkCompleted ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C' AND
				vSMDetailTransaction.SMWorkCompletedID NOT IN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompletedGL)
			
			-- Create new entrys in SMGLEntry and SMGLDetailTransaction for cost wip transfers
			INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal, TransactionsShouldBalance)
				OUTPUT INSERTED.SMGLEntryID, INSERTED.SMWorkCompletedID
						INTO @SMGLEntry
			SELECT DISTINCT vSMDetailTransaction.SMWorkCompletedID, vSMCO.GLJrnl, 0 TransactionsShouldBalance
			FROM dbo.vPRLedgerUpdateDistribution
				INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
				INNER JOIN dbo.vSMWorkCompleted ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
				INNER JOIN dbo.vSMCO ON vSMWorkCompleted.SMCo = vSMCO.SMCo
			WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C'

			INSERT dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT SMGLEntry.SMGLEntryID, 1, vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount, vSMDetailTransaction.Amount, @prenddate, @gldesc
			FROM dbo.vPRLedgerUpdateDistribution
				INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
				INNER JOIN @SMGLEntry SMGLEntry ON vSMDetailTransaction.SMWorkCompletedID = SMGLEntry.SMWorkCompletedID
			WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C' AND vSMDetailTransaction.IsReversing = 0

			DECLARE @GLEntriesToDelete TABLE (GLEntryID bigint NULL, GLTransactionEntryID bigint NULL)

			UPDATE vSMWorkCompletedGL
			SET CostGLEntryID = vSMGLDetailTransaction.SMGLEntryID, CostGLDetailTransactionEntryID = vSMGLDetailTransaction.SMGLEntryID, CostGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
				OUTPUT DELETED.CostGLEntryID, DELETED.CostGLDetailTransactionEntryID
					INTO @GLEntriesToDelete
			FROM @SMGLEntry SMGLEntry
				INNER JOIN dbo.vSMWorkCompletedGL ON SMGLEntry.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
				INNER JOIN dbo.vSMGLDetailTransaction ON SMGLEntry.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID

			--Get rid of the GL Entries that are no longer pointed to
			DELETE dbo.vSMGLEntry
			WHERE SMGLEntryID IN (SELECT GLEntryID FROM @GLEntriesToDelete
				UNION SELECT GLTransactionEntryID FROM @GLEntriesToDelete)

			COMMIT TRAN
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
       		select @errmsg = 'SM GL WIP failed: '+ ERROR_MESSAGE(), @rcode = 1
       		goto bspexit
		END CATCH
	
      	 -- cursor on PR GL interface table - #120831 use local, fast_forward cursor
       declare bcGL cursor local fast_forward for
       select Mth, GLCo, GLAcct, convert(numeric(12,2),sum(Amt)), convert(numeric(12,2),sum(OldAmt)),
   		convert(numeric(12,2),sum(Hours)), convert(numeric(12,2),sum(OldHours))
       from bPRGL
      	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
       	group by Mth, GLCo, GLAcct
       	order by Mth, GLCo, GLAcct	-- #127804 - add order by
   
       open bcGL
      	select @openGL = 1
   
   	next_GL:
   		fetch next from bcGL into @Mth, @glco, @glacct, @amt, @oldamt, @hrs, @oldhrs
           
   		if @@fetch_status <> 0 goto end_GL_update
   
           if @hrs <> 0 or @oldhrs <> 0 select @amt = @hrs, @oldamt = @oldhrs --post cross reference hours to bGLDT amount field
   
           if @amt = @oldamt goto update_old 	-- #19636, skip GL update, but update 'old' amounts in bPRGL
   
           if @batchmth is null or @batchmth <> @Mth
           	begin
              	-- add a Batch for each month updated in GL
               exec @batchid = bspHQBCInsert @prco, @Mth, 'PR Update', 'bPRGL', 'N', 'N', @prgroup, @prenddate, @errmsg output
               if @batchid = 0
   	           	begin
   		       	select @errmsg = 'Unable to add a Batch to update GL!', @rcode = 1
   		       	goto bspexit
   	          	end
               --- update batch status as 'posting in progress'
               update bHQBC set Status = 4, DatePosted = @postdate
               where Co = @prco and Mth = @Mth and BatchId = @batchid
   
               select @batchmth = @Mth
               select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
               end
   
           begin transaction

           -- back out 'old - previously interfaced' amounts
           if @oldamt <> 0
               begin
              	-- get next available transaction # for GLDT
   	        exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @Mth, @errmsg output
   	        if @gltrans = 0
                   begin
     	            select @errmsg = 'Unable to get another transaction # for GL Detail!', @rcode = 1
                   goto GL_error
     	            end
    	        insert bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
    	        	Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    	        values(@glco, @Mth, @gltrans, @glacct, @jrnl, @glref, @prco, 'PR Update', @prenddate,
   	 	        @postdate, @gldesc, @batchid, -(@oldamt), 0, 'N', null, 'N')
   	   		if @@rowcount = 0
   	      		begin
    				select @errmsg = 'Unable to add GL Detail entry!', @rcode = 1
   	      		goto GL_error
     	      		end
   	   		end
   
   		-- add in 'new - current value' amounts
   		if @amt <> 0
   			begin
          		-- get next available transaction # for GLDT
           	exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @Mth, @errmsg output
           	if @gltrans = 0
               	begin
   	            select @errmsg = 'Unable to get another transaction # for GL Detail!', @rcode=1
               	goto GL_error
   	            end
   	        insert bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
   	        	Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
   	        values(@glco, @Mth, @gltrans, @glacct, @jrnl, @glref, @prco, 'PR Update', @prenddate,
    	        	@postdate, @gldesc, @batchid, @amt, 0, 'N', null, 'N')
      			if @@rowcount = 0
         			begin
          			select @errmsg = 'Unable to add GL Detail entry!', @rcode = 1
         			goto GL_error
   	      		end
      			end

   		update_old:		-- replace 'old' with 'current' to keep track of interfaced amounts
   			update bPRGL set OldAmt = Amt, OldHours = Hours --issue #14014
   			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   		   		and Mth = @Mth and GLCo = @glco and GLAcct = @glacct
			
			IF @amt = @oldamt --If the amounts are equal meaning nothing changed then nothing is posted to GL and therefore the reconciliation records should not be captured.
			BEGIN
				--Capture the SM reconciliation records
				DELETE vSMDetailTransaction
				FROM dbo.vPRLedgerUpdateDistribution
					INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
				WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C' AND vSMDetailTransaction.PRMth = @Mth AND vSMDetailTransaction.GLCo = @glco AND vSMDetailTransaction.GLAccount = @glacct
			END
			ELSE
			BEGIN
				--Capture the SM reconciliation records
				UPDATE vSMDetailTransaction
				SET PRLedgerUpdateDistributionID = NULL, Posted = 1, BatchId = @batchid, GLInterfaceLevel = 1/*Summary Interfaced*/
				FROM dbo.vPRLedgerUpdateDistribution
					INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
				WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C' AND vSMDetailTransaction.PRMth = @Mth AND vSMDetailTransaction.GLCo = @glco AND vSMDetailTransaction.GLAccount = @glacct
			END
          		if @@trancount > 0 commit transaction	-- #19636 - only commit if needed, no trans if old = current 
      			goto next_GL
   
       	GL_error:
         		rollback transaction
        		goto bspexit
   
   	end_GL_update:
   		close bcGL
   		deallocate bcGL
   		select @openGL = 0
   
		--Delete any SM reconciliation records that weren't posted so posting doesn't error.
		DELETE vSMDetailTransaction
		FROM dbo.vPRLedgerUpdateDistribution
			INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
		WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C'
   
           -- close the Batch Control entries
           update bHQBC set Status = 5, DateClosed = getdate()
   	    where Co = @prco and  TableName = 'bPRGL' and PRGroup = @prgroup and PREndDate = @prenddate
   
   	end
   	else
   	begin
   		--Capture the transactions for SM WIP transfers
		UPDATE vSMDetailTransaction
		SET PRLedgerUpdateDistributionID = NULL, Posted = 1, GLInterfaceLevel = 0/*No Update Interfaced*/
		FROM dbo.vPRLedgerUpdateDistribution
			INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
		WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'C'
   	end
   
   -- CM and PR Payment History update - these updates are required
   exec @rcode = bspPRUpdatePostCM @prco, @prgroup, @prenddate, @postdate, @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- Employee Accums
   exec @rcode = bspPRUpdatePostAccums @prco, @prgroup, @prenddate, @errmsg output
   if @rcode <> 0 goto bspexit
   
	DECLARE @SMGLEntryTransaction TABLE (Processed bit NOT NULL DEFAULT(0), JCCo bCompany NOT NULL, Mth bMonth NOT NULL, SMWorkCompletedID bigint NOT NULL, RevenueGLEntryID bigint NULL, IsReversing bit NOT NULL)
	DECLARE @BatchId int, @SMWorkCompletedID bigint, @RevenueGLEntryID bigint, @JCCo bCompany, @IsReversing bit, @HQBatchDistributionID bigint, @PRLedgerUpdateDistributionID bigint
	
	SELECT @PRLedgerUpdateDistributionID = PRLedgerUpdateDistributionID
	FROM dbo.vPRLedgerUpdateDistribution
	WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate

	--Retrieve all new GLEntrys tied to the pay period.
	--Posting will be done by month.
	INSERT @SMGLEntryTransaction (JCCo, Mth, SMWorkCompletedID, RevenueGLEntryID, IsReversing)
	SELECT vSMWorkOrder.JCCo, vPRLedgerUpdateMonth.Mth, vSMWorkCompleted.SMWorkCompletedID, vGLEntry.GLEntryID, 0 IsReversing
	FROM dbo.vPRLedgerUpdateMonth
		INNER JOIN dbo.vGLEntry ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vGLEntry.PRLedgerUpdateMonthID
		INNER JOIN dbo.vSMWorkCompletedGLEntry ON vGLEntry.GLEntryID = vSMWorkCompletedGLEntry.GLEntryID
		INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedGLEntry.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
	WHERE vPRLedgerUpdateMonth.PRCo = @prco AND vPRLedgerUpdateMonth.PRGroup = @prgroup AND vPRLedgerUpdateMonth.PREndDate = @prenddate AND vPRLedgerUpdateMonth.Posted = 0 AND vGLEntry.[Source] = 'SM Job'

	--For work completed that has had revenue captured against it a reversing entry needs to be created.
	INSERT @SMGLEntryTransaction (JCCo, Mth, SMWorkCompletedID, IsReversing)
	SELECT vSMWorkOrder.JCCo, vPRLedgerUpdateMonth.Mth, vSMWorkCompleted.SMWorkCompletedID, 1 IsReversing
	FROM dbo.vPRLedgerUpdateMonth
		INNER JOIN dbo.vGLEntry ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vGLEntry.PRLedgerUpdateMonthID
		INNER JOIN dbo.vSMWorkCompleted ON vGLEntry.GLEntryID = vSMWorkCompleted.RevenueGLEntryID
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
	WHERE vPRLedgerUpdateMonth.PRCo = @prco AND vPRLedgerUpdateMonth.PRGroup = @prgroup AND vPRLedgerUpdateMonth.PREndDate = @prenddate

	--Replace the Trans # with N/A if it didn't get replaced from the job cost posting.
	UPDATE dbo.vGLEntryTransaction
	SET [Description] = REPLACE([Description], 'Trans #', 'N/A')
	WHERE GLEntryID IN (SELECT RevenueGLEntryID FROM @SMGLEntryTransaction)

	WHILE EXISTS(SELECT 1 FROM @SMGLEntryTransaction)
	BEGIN
		BEGIN TRY
			BEGIN TRAN
				SELECT TOP 1 @Mth = Mth
				FROM @SMGLEntryTransaction
				
				-- add a Batch for each month updated in JC - created as 'open', and 'in use'
				EXEC @BatchId = dbo.bspHQBCInsert @co = @prco, @month = @Mth, @source = 'PR Update', @batchtable = 'SMWorkCompletedBatch', @restrict = 'N', @adjust = 'N', @prgroup = @prgroup, @prenddate = @prenddate, @errmsg = @errmsg OUTPUT
				IF @BatchId = 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END
				
				--For each GLEntry that needs to be posted for the current processing month a vHQBatchDistribution
				--record is created to relate the GLEntry to the batch. If the GLEntry was already posted a reversing
				--entry is created
				WHILE EXISTS(SELECT 1 FROM @SMGLEntryTransaction WHERE Mth = @Mth AND Processed = 0)
				BEGIN
					UPDATE TOP (1) @SMGLEntryTransaction
					SET Processed = 1, @SMWorkCompletedID = SMWorkCompletedID, @RevenueGLEntryID = RevenueGLEntryID, @JCCo = JCCo, @IsReversing = IsReversing
					WHERE Mth = @Mth AND Processed = 0
				
					INSERT dbo.vHQBatchDistribution (Co, Mth, BatchId, InterfacingCo, IsReversing)
					VALUES (@prco, @Mth, @BatchId, @JCCo, @IsReversing)
					
					SET @HQBatchDistributionID = SCOPE_IDENTITY()

					IF @IsReversing = 1
					BEGIN
						EXEC @RevenueGLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance = 0, @HQBatchDistributionID = @HQBatchDistributionID, @msg = @errmsg OUTPUT
						IF @RevenueGLEntryID = 0
						BEGIN
							ROLLBACK TRAN
							RETURN 1
						END

						INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
						SELECT @RevenueGLEntryID, ROW_NUMBER() OVER(ORDER BY GLCo, GLAccount), 'SM Job', GLCo, GLAccount, Amount, @prenddate, [Description]
						FROM
						(
							SELECT vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, -SUM(vGLEntryTransaction.Amount) Amount, vGLEntryTransaction.[Description]
							FROM dbo.vSMWorkCompleted
								INNER JOIN dbo.vGLEntry ON vGLEntry.GLEntryID IN (vSMWorkCompleted.RevenueGLEntryID, vSMWorkCompleted.RevenueSMWIPGLEntryID, vSMWorkCompleted.RevenueJCWIPGLEntryID)
								INNER JOIN dbo.vGLEntryTransaction ON vGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID
							WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID
							GROUP BY vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, vGLEntryTransaction.[Description]
						) ReversingEntries
						WHERE Amount <> 0
						
						INSERT dbo.vSMWorkCompletedGLEntry (GLEntryID, GLTransactionForSMDerivedAccount, SMWorkCompletedID)
						VALUES (@RevenueGLEntryID, 1, @SMWorkCompletedID)

						--Build reversing reconciliation record
						INSERT dbo.vSMDetailTransaction (IsReversing, Posted, PRLedgerUpdateDistributionID, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, GLCo, GLAccount, Amount)
						SELECT 1 IsReversing, 0 Posted, @PRLedgerUpdateDistributionID, vSMWorkCompleted.CostDetailID, vSMWorkCompleted.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, 2 LineType/*2 for labor*/, 'R' TransactionType/*R for revenue*/, @prco, @Mth, vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, -vGLEntryTransaction.Amount
						FROM dbo.vSMWorkCompleted
							INNER JOIN dbo.vGLEntry ON vGLEntry.GLEntryID = ISNULL(vSMWorkCompleted.RevenueSMWIPGLEntryID, vSMWorkCompleted.RevenueGLEntryID)
							INNER JOIN dbo.vSMWorkCompletedGLEntry ON vGLEntry.GLEntryID = vSMWorkCompletedGLEntry.GLEntryID
							INNER JOIN dbo.vGLEntryTransaction ON vSMWorkCompletedGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID AND vSMWorkCompletedGLEntry.GLTransactionForSMDerivedAccount = vGLEntryTransaction.GLTransaction
							INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.IsSession = 0
							INNER JOIN dbo.vSMWorkOrderScope ON vSMWorkCompletedDetail.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkCompletedDetail.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWorkCompletedDetail.Scope = vSMWorkOrderScope.Scope
							INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
						WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID
					END
					ELSE
					BEGIN
						UPDATE dbo.vGLEntry
						SET HQBatchDistributionID = @HQBatchDistributionID
						WHERE GLEntryID = @RevenueGLEntryID
					END
				END

				EXEC @rcode = dbo.vspSMJobCostPostGL @GLEntrySource = 'SM Job', @BatchCo = @prco, @BatchMth = @Mth, @BatchId = @BatchId, @PostedDate = @postdate, @msg = @errmsg OUTPUT
	    		IF @rcode <> 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END

				--Capture the SM reconciliation records
				UPDATE vSMDetailTransaction
				SET PRLedgerUpdateDistributionID = NULL, Posted = 1, BatchId = @BatchId
				FROM dbo.vPRLedgerUpdateDistribution
					INNER JOIN dbo.vSMDetailTransaction ON vPRLedgerUpdateDistribution.PRLedgerUpdateDistributionID = vSMDetailTransaction.PRLedgerUpdateDistributionID
				WHERE vPRLedgerUpdateDistribution.PRCo = @prco AND vPRLedgerUpdateDistribution.PRGroup = @prgroup AND vPRLedgerUpdateDistribution.PREndDate = @prenddate AND vSMDetailTransaction.TransactionType = 'R' AND vSMDetailTransaction.Mth = @Mth

				EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @prco, @BatchMth = @Mth, @BatchId = @BatchId, @msg = @errmsg OUTPUT
				IF @rcode <> 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END

				DELETE @SMGLEntryTransaction
				WHERE Mth = @Mth
			COMMIT TRAN
		END TRY
		BEGIN CATCH
    		--If the error is due to a transaction count mismatch in vspSMJobCostPostGL
			--then it is more helpful to keep the error message from vspSMJobCostPostGL.
			IF ERROR_NUMBER() <> 266 SET @errmsg = ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK TRAN
			
			RETURN 1
		END CATCH
	END

   -- updates successfully completed, set Final GL Interface flag is Pay Period is closed
   if @status = 1
   	begin
          	update bPRPC set GLInterface = 'Y'  -- final GL interface is complete
          	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
           end
   
   bspexit:
   	if @openGL = 1
   		begin
   		close bcGL
   		deallocate bcGL
   		end
   
       --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdatePostGL]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdatePostGL] TO [public]
GO
