SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCXBPost    Script Date: 2/12/97 3:25:02 PM ******/
    CREATE    procedure [dbo].[bspJCXBPost]
    /***********************************************************
     * CREATED BY:  CJW 4/29/97
     * MODIFIED By : GG 01/26/99
     *               GG 10/07/99 Fix null GL Description Control
     *              CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
     *	 			TV - 23061 added isnulls
     *       		  DANF 03/15/05 - #27294 - Remove scrollable cursor.
	 *				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
     * USAGE:
     * Posts a validated batch of JCXB entries
     * deletes successfully posted bJCXB rows
     * clears bJCXA and bHQCC when complete
     *
     * INPUT PARAMETERS
     *   JCCo        JC Co
     *   Month       Month of batch
     *   BatchId     Batch ID to validate
     *   PostingDate Posting date to write out if successful
     * OUTPUT PARAMETERS
     *   @errmsg     if something went wrong
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID,
	@dateposted bDate = null, @errmsg varchar(60) output)
as
set nocount on

declare @rcode int, @opencursor tinyint, @source bSource, @tablename char(20), @phase bPhase, @costtype tinyint,
		@inuseby bVPUserName, @status tinyint, @seq int,
		@glcloselevel tinyint, @glcloseoverride bYN, @glclosejournal bJrnl,
		@glclosedetaildesc varchar(60), @glclosesummarydesc varchar(30), @batchseq int,
		@transtype char(1), @costtrans bTrans, @job bJob, @actualdate bDate,
		@jctranstype varchar(2), @description bTransDesc, @glco bCompany, @gltransacct bGLAcct,
		@gloffsetacct bGLAcct, @reversalstatus tinyint, @um bUM, @hours bHrs, @units bUnits,
		@cost bDollar, @glacct bGLAcct, @gltrans bTrans, @amount bDollar,
		@origmth bMonth, @origcosttrans bTrans, @glref bGLRef,
		@errorstart varchar(50), @subtype char(1), @stmtdate bDate, @inusebatchid bBatchID,
		@desccontrol varchar(60), @opencursorjcxa tinyint, @desc varchar(60), @findidx int,
		@found varchar(30), @oldnew tinyint, @lastseq int,@lastcontractmth bMonth, @lastjobmth bMonth,@tmpstring varchar(60),
		@contract bContract, @closedate bDate, @department bDept, @actdate bDate, @softfinal varchar(1),
		@Notes varchar(256)

	--SM related variables
	DECLARE @SMWorkCompletedID bigint, @GLEntryID bigint, @GLTranaction int
	DECLARE @SMJobWIP TABLE (SMWorkCompletedID bigint, ActualCost bDollar, [Description] bTransDesc, GLCo bCompany, OpenWIPAccount bGLAcct, ClosedWIPAccount bGLAcct)
   
    set nocount on
    select @rcode = 0, @lastseq=0
    /* set open cursor flags to false */
    select @opencursor = 0, @opencursorjcxa = 0
    /* get GL interface info from JCCO */
    select @glclosejournal = GLCloseJournal, @glclosedetaildesc = GLCloseDetailDesc,
    	@glclosesummarydesc = GLCloseSummaryDesc, @glcloselevel = GLCloseLevel
    	from bJCCO where JCCo = @co
    if @@rowcount = 0
    	begin
        	select @errmsg = 'Missing JC Company!', @rcode = 1
        	goto bspexit
       	end
    /* check for date posted */
    if @dateposted is null
    	begin
    	select @errmsg = 'Missing posting date!', @rcode = 1
    	goto bspexit
    	end
    /* validate HQ Batch */
    select @source = 'JC Close'
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCXB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
    if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
    	begin
    	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
    	goto bspexit
    	end
    /* set HQ Batch status to 4 (posting in progress) */
    update bHQBC
    	set Status = 4, DatePosted = @dateposted
    	where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
    /* declare cursor on JC Close Batch for posting */
    declare bcJCXB cursor for select Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal, BatchSeq
    	from bJCXB where Co = @co and Mth = @mth and BatchId = @batchid for update
    /* open cursor */
   
    open bcJCXB
    /* set open cursor flag to true */
    select @opencursor = 1
    /* loop through all rows in this batch */
    close_contract_loop:
    	fetch next from bcJCXB into @contract, @job, @lastcontractmth, @lastjobmth, @closedate, @softfinal, @batchseq
    	if (@@fetch_status <> 0) goto jc_posting_end
    	begin transaction	/* Need to close contract, triggers should close all jobs associated with contract */
    	update bJCCM
    	   set ContractStatus = case @softfinal when 'S' then 2 else 3 end, ActualCloseDate = @closedate,
    		    MonthClosed =@mth ,
    	         InBatchMth = null, InUseBatchId = null
    	      where bJCCM.JCCo = @co and bJCCM.Contract = @contract

		--When a job is hard closed and GL is transfered from the open account to the close account then SM records are updated to capture the transactions so that if any changes are made after
		--the job is closed reversing entries are properly created.
		IF @glcloselevel <> 0 AND dbo.vfIsEqual(@softfinal, 'S') = 0
		BEGIN
			INSERT @SMJobWIP
			SELECT vSMWorkCompleted.SMWorkCompletedID, vJCCostEntryTransaction.ActualCost, dbo.vfToString(REPLACE(REPLACE(RTRIM(bJCCO.GLCloseDetailDesc), 'Dept', dbo.vfToString(bJCCI.Department)), 'Contract', dbo.vfToString(bJCCI.[Contract]))),
				bJCDM.GLCo, ISNULL(bJCDO.OpenWIPAcct, bJCDC.OpenWIPAcct), ISNULL(bJCDO.ClosedExpAcct, bJCDC.ClosedExpAcct)
			FROM dbo.vJCCostEntryTransaction
				INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompleted.JCCostEntryID = vJCCostEntryTransaction.JCCostEntryID
				INNER JOIN dbo.bJCJP ON vJCCostEntryTransaction.JCCo = bJCJP.JCCo AND vJCCostEntryTransaction.Job = bJCJP.Job AND vJCCostEntryTransaction.PhaseGroup = bJCJP.PhaseGroup AND vJCCostEntryTransaction.Phase = bJCJP.Phase
				INNER JOIN dbo.bJCCI ON bJCJP.JCCo = bJCCI.JCCo AND bJCJP.[Contract] = bJCCI.[Contract] AND bJCJP.Item = bJCCI.Item
				INNER JOIN dbo.bJCDM ON bJCCI.JCCo = bJCDM.JCCo AND bJCCI.Department = bJCDM.Department
				INNER JOIN dbo.bJCCO ON vJCCostEntryTransaction.JCCo = bJCCO.JCCo
				LEFT JOIN dbo.bJCDO ON bJCCI.JCCo = bJCDO.JCCo AND bJCCI.Department = bJCDO.Department AND vJCCostEntryTransaction.Phase = bJCDO.Phase
				LEFT JOIN dbo.bJCDC ON bJCCI.JCCo = bJCDC.JCCo AND bJCCI.Department = bJCDC.Department AND vJCCostEntryTransaction.CostType = bJCDC.CostType
			WHERE vJCCostEntryTransaction.JCCo = @co and vJCCostEntryTransaction.Job = @job

			DELETE @SMJobWIP
			WHERE OpenWIPAccount = ClosedWIPAccount

			WHILE EXISTS(SELECT 1 FROM @SMJobWIP)
			BEGIN
				SELECT TOP 1 @SMWorkCompletedID = SMWorkCompletedID
				FROM @SMJobWIP
				
				SELECT @GLEntryID = RevenueJCWIPGLEntryID
				FROM dbo.vSMWorkCompleted
				WHERE SMWorkCompletedID = @SMWorkCompletedID
				
				IF @GLEntryID IS NULL
				BEGIN
					EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM JC WIP', @TransactionsShouldBalance =  1, @msg = @errmsg OUTPUT

					IF @GLEntryID = -1 RETURN 1
					
					SET @GLTranaction = 0
					
					UPDATE vSMWorkCompleted
					SET RevenueJCWIPGLEntryID = @GLEntryID
					WHERE SMWorkCompletedID = @SMWorkCompletedID
				END
				ELSE
				BEGIN
					SELECT @GLTranaction = ISNULL(MAX(GLTransaction), 0)
					FROM vGLEntryTransaction
					WHERE GLEntryID = @GLEntryID
				END
				
				INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
				SELECT @GLEntryID, ROW_NUMBER() OVER(ORDER BY SMWorkCompletedID) + @GLTranaction, Transactions.GLCo, Transactions.GLAccount, Transactions.ActualCost, Transactions.ActDate, Transactions.[Description]
				FROM @SMJobWIP SMJobWIP
					CROSS APPLY (
						SELECT GLCo, ClosedWIPAccount GLAccount, ActualCost, @dateposted ActDate, [Description]
						UNION ALL
						SELECT GLCo, OpenWIPAccount, -ActualCost, @dateposted, [Description]
					) Transactions
				WHERE SMJobWIP.SMWorkCompletedID = @SMWorkCompletedID
				
				DELETE @SMJobWIP WHERE SMWorkCompletedID = @SMWorkCompletedID
			END
		END

    	/* delete current row from cursor */
    	delete from bJCXB where Co = @co and Mth = @mth and BatchId = @batchid and 
			Contract = @contract and (Job = @job or Job is null)
   
    	/* commit transaction */
    	commit transaction
    	goto close_contract_loop
    close_contract_error:		/* error occured within transaction - rollback any updates and continue */
    	rollback transaction
    	goto close_contract_loop
    jc_posting_end:			/* no more rows to process */
    	/* make sure batch is empty */
    	if exists(select * from bJCXB where Co = @co and Mth = @mth and BatchId = @batchid)
    		begin
    		select @errmsg = 'Not all JC batch entries were posted - unable to close batch!', @rcode = 1
    		goto bspexit
    		end
    gl_update:	/* update GL using entries from bJCXA */
    	if @glcloselevel = 0	 /* no update */
    		begin
    	    	delete bJCXA where Co = @co and Mth = @mth and BatchId = @batchid
    		goto gl_update_end
    	  	end
    	/* set GL Reference using Batch Id - right justified 10 chars */
    	select @glref = space(10-datalength(convert(varchar(10),@batchid))) + convert(varchar(10),@batchid)
    	if @glcloselevel = 1	 /* summary - one entry per GL Co/Department, unless GL account flagged for detail */
    	   begin
                	/* declare 'summary' cursor on JCXA Table */
                --#142278
                 DECLARE bcsumJCXA CURSOR local fast_forward FOR 
					 SELECT bJCXA.GLCo,
							bJCXA.GLAcct,
							bJCXA.Department,
							ISNULL(CONVERT (numeric(12, 2), SUM(bJCXA.Amount)), 0)
					 FROM   dbo.bJCXA
							JOIN dbo.bGLAC ON  bGLAC.GLCo = bJCXA.Co
												AND bGLAC.GLAcct = bJCXA.GLAcct
					 WHERE  bJCXA.Mth = @mth
							AND bJCXA.BatchId = @batchid
							AND bGLAC.InterfaceDetail = 'N'
							AND bJCXA.Co = @co
					 GROUP BY bJCXA.GLCo,
							bJCXA.GLAcct,
							bJCXA.Department
							
                	/* open cursor */
                	open bcsumJCXA
                	select @opencursorjcxa = 1
    		gl_summary_posting_loop:
    	     		fetch next from bcsumJCXA into @glco, @glacct, @department, @amount
    	     		if @@fetch_status <> 0 goto gl_summary_posting_end
    	           	begin transaction
        	           	   /* get next available transaction # for GLDT */
    	           	   select @tablename = 'bGLDT'
    	           	   exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
    	           	   if @gltrans = 0 goto gl_summary_posting_error
    	           	   insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
    				ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
    			        Adjust, InUseBatchId, Purge)
     		           values(@glco, @mth, @gltrans, @glacct, @glclosejournal, @glref, @co, 'JC Close',
    			@dateposted, @dateposted, @glclosesummarydesc, @batchid, @amount, 0, 'N', null, 'N')
    			   if @@rowcount = 0 goto gl_summary_posting_error
      	           	   delete bJCXA where Co = @co and Mth = @mth and BatchId = @batchid
                                   and GLCo = @glco and GLAcct = @glacct
                      	commit transaction
    			goto gl_summary_posting_loop
    		gl_summary_posting_error:	/* error occured within transaction - rollback any updates and continue */
    			rollback transaction
    			goto gl_summary_posting_loop
    	  end
    	gl_summary_posting_end:	/* no more rows to process */
    	    if @opencursorjcxa <> 0
    		begin
    	    	   close bcsumJCXA
                	   deallocate bcsumJCXA
                	   select @opencursorjcxa = 0
    		end
    	/* detail update to GL for everything remaining in bJCXA */
    	declare bcJCXA cursor local fast_forward for select GLCo, GLAcct, Department, Contract, ActDate, Description, Amount
    	    	from bJCXA where Co = @co and Mth = @mth and BatchId = @batchid
    	/* open cursor */
            open bcJCXA
            select @opencursorjcxa = 1
    	gl_detail_posting_loop:
    		fetch next from bcJCXA into @glco, @glacct, @department, @contract, @actdate, @description, @amount
    	     	if @@fetch_status <> 0 goto gl_detail_posting_end
    	      	begin transaction
    	       	/* parse out the description */
    	       	select @desccontrol = isnull(rtrim(@glclosedetaildesc),'')
    	       	select @desc = ''
                   	while (@desccontrol <> '')
                    	begin
                     	select @findidx = charindex('/',@desccontrol)
                     	if @findidx = 0
    		    		begin
                         		select @found = @desccontrol
    		     		select @desccontrol = ''
    		    		end
                     	else
    		    		begin
        		     		select @found=substring(@desccontrol,1,@findidx-1)
    		     		select @desccontrol = substring(@desccontrol,@findidx+1,60)
                        		end
                     	if @found = 'Dept'
                        		select @desc = @desc + '/' + @department
                     	if @found = 'Contract'
                        		select @desc = @desc + '/' + @contract
    			end
   
    		 -- remove leading '/'
          		if substring(@desc,1,1)='/' select @desc = substring(@desc,2,datalength(@desc))
   
     	       	/* get next available transaction # for GLDT */
    	       	select @tablename = 'bGLDT'
    	       	exec @gltrans = bspHQTCNextTrans @tablename, @glco, @mth, @errmsg output
    	       	if @gltrans = 0 goto gl_detail_posting_error
    	       	insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
    			ActDate, DatePosted, Description, BatchId, Amount, RevStatus,
    			Adjust, InUseBatchId, Purge)
    		values(@glco, @mth, @gltrans, @glacct, @glclosejournal, @glref, 	@co, 'JC Close', @actdate,
    			@dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
    		if @@rowcount = 0 goto gl_detail_posting_error
      	       	delete from bJCXA where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco
      	       		and GLAcct = @glacct and Department = @department and Contract = @contract
    		commit transaction
    		goto gl_detail_posting_loop
    	gl_detail_posting_error:	/* error occured within transaction - rollback any updates and continue */
    		rollback transaction
    		goto gl_detail_posting_loop
    gl_detail_posting_end:	/* no more rows to process */
    	close bcJCXA
            deallocate bcJCXA
            select @opencursorjcxa = 0
    gl_update_end:
    	/* make sure GL Audit is empty */
    	if exists(select * from bJCXA where Co = @co and Mth = @mth and BatchId = @batchid)
    		begin
    		select @errmsg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
    		goto bspexit
    		end
   
    -- set interface levels note string
       select @Notes=Notes from bHQBC
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'GL Cost Interface Level set at: ' + isnull(convert(char(1), a.GLCostLevel),'') + char(13) + char(10) +
           'GL Revenue Interface Level set at: ' + isnull(convert(char(1), a.GLRevLevel),'') + char(13) + char(10) +
           'GL Close Interface Level set at: ' + isnull(convert(char(1), a.GLCloseLevel),'') + char(13) + char(10) +
           'GL Material Interface Level set at: ' + isnull(convert(char(1), a.GLMaterialLevel),'') + char(13) + char(10)
       from bJCCO a where JCCo=@co
   
  
    /* delete HQ Close Control entries */
    delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    /* set HQ Batch status to 5 (posted) */
    update bHQBC
    	set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
    	where Co = @co and Mth = @mth and BatchId = @batchid
    	if @@rowcount = 0
    		begin
    		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   
    		goto bspexit
    		end
    bspexit:
    	if @opencursor = 1
    		begin
    		close bcJCXB
    		deallocate bcJCXB
    		end
    	if @opencursorjcxa = 1
    		begin
   
    		close bcJCXA
    		deallocate bcJCXA
    		end
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCXBPost] TO [public]
GO
