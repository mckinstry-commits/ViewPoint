SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRUpdatePostCM]
/***********************************************************
* CREATED BY: GG 07/13/98
* MODIFIED By : GG 10/14/98
*              GG 08/13/99     Fixed to backout voided EFTs from bCMDT
*				EN 10/9/02 - issue 18877 change double quotes to single
*				EN 12/09/03 - issue 23061  added isnull check, with (nolock), and dbo
*				EN 2/9/05 - issue 26490  wrong payee could be written to bCMDT
*				GG 10/17/06 - #120831 use local fast_forward cursors
 *				JayR 08/09/2012 TK-14356 Fix an Insert were the columns were not fully specified.
*				EN/MV 9/18/2012 B-10153/TK-17826 added code to include potential payback/payback update amounts when validate for CM posting
*
* USAGE:
* Called from bspPRUpdatePostGL to perform updates to
* CM and PR Payment History whenever a GL interface is run.
*
* INPUT PARAMETERS
*   @prco   		PR Company
*   @prgroup  		PR Group to validate
*   @prenddate		Pay Period Ending Date
*   @postdate		Posting Date used for transaction detail
*
* OUTPUT PARAMETERS
*   @errmsg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@prco bCompany, @prgroup bGroup, @prenddate bDate, @postdate bDate, @errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @batchmth bMonth, @openEmplSeq tinyint, @employee bEmployee, @payseq tinyint, @cmco bCompany,
   @cmacct bCMAcct, @paymethod char(1), @cmref bCMRef, @cmrefseq tinyint, @eftseq smallint, @chktype char(1),
   @paiddate bDate, @mth bMonth, @totalhours bHrs, @totalearns bDollar, @totaldedns bDollar, @dthours bHrs,
   @dtearns bDollar, @nontrueamt bDollar, @dtdedns bDollar, @netpay bDollar, @glco bCompany, @cmglacct bGLAcct,
   @cmtranstype tinyint, @payee varchar(20), @desc bDesc, @batchid int, @cmtrans int, @openVoid tinyint,
   @paidamt bDollar, @voidmemo bDesc, @reuse bYN, @hours bHrs, @earns bDollar, @dedns bDollar
   
   select @rcode = 0, @batchmth = null
   
   -- cursor on PR Employee Sequence Control table - #120831 use local, fast_forward cursor
   declare bcEmplSeq cursor local fast_forward for
   select Employee, PaySeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType,
   	PaidDate, PaidMth, Hours, Earnings, Dedns
   from dbo.bPRSQ with (nolock)
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	and CMRef is not null and Processed = 'Y' and CMInterface = 'N' -- must be paid, processed, and not interfaced
   order by PaidMth, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq
   
   open bcEmplSeq
   select @openEmplSeq = 1
   
   next_EmplSeq:
   	fetch next from bcEmplSeq into @employee, @payseq, @cmco, @cmacct, @paymethod, @cmref,
   		@cmrefseq, @eftseq, @chktype, @paiddate, @mth, @totalhours, @totalearns, @totaldedns
   	if @@fetch_status <> 0 goto end_EmplSeq
   
   	-- must not have any unposted timecards
   	if exists(select * from dbo.bPRTB b with (nolock)
   		join dbo.bHQBC h with (nolock) on b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId
   		join dbo.bPRPC p with (nolock) on p.PRCo = h.Co and p.PRGroup = h.PRGroup and p.PREndDate = h.PREndDate
                  	where p.PRCo = @prco and p.PRGroup = @prgroup and p.PREndDate = @prenddate
   			and b.Employee = @employee and b.PaySeq = @payseq)
   		goto next_EmplSeq
   
   	-- amounts in Seq Control must match sums from Pay Seq Totals
       	select @dthours = isnull(sum(Hours),0), @dtearns = isnull(sum(Amount),0)    -- total hours and earnings
       	from dbo.bPRDT with (nolock)
       	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
           	and PaySeq = @payseq and EDLType = 'E'
   
      	select @nontrueamt = isnull(sum(d.Amount),0)     --  non-true earnings
       	from dbo.bPRDT d with (nolock)
       	join dbo.bPREC e with (nolock) on e.PRCo = d.PRCo and e.EarnCode = d.EDLCode
       	where d.PRCo = @prco and d.PRGroup = @prgroup and d.PREndDate = @prenddate and d.Employee = @employee
           	and d.PaySeq = @payseq and d.EDLType = 'E' and e.TrueEarns = 'N'
   
       	SELECT @dtdedns = ISNULL(SUM(CASE UseOver WHEN 'Y' THEN OverAmt ELSE Amount END),0) +     -- deductions
       					  ISNULL(SUM(CASE PaybackOverYN WHEN 'Y' THEN PaybackOverAmt ELSE PaybackAmt END),0)
       	from dbo.bPRDT with (nolock)
       	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
           	and PaySeq = @payseq and EDLType = 'D'
   
       	-- make sure totals in bPRSQ match sums from bPRDT
       	if @totalhours <> @dthours or @totalearns <> @dtearns or @totaldedns <> @dtdedns goto next_EmplSeq
   
       	select @netpay = @totalearns - @totaldedns
   
       	-- get CM GL Account    -- already validated
       	select @glco = GLCo, @cmglacct = GLAcct
      	from dbo.bCMAC with (nolock)
       	where CMCo = @cmco and CMAcct = @cmacct
       	if @paymethod = 'C' -- Check
           	begin
           	select @cmtranstype = 1
           	select @payee = convert(varchar(20),@employee)
           	select @desc = isnull(LastName,'') + ', ' + isnull(FirstName,'') + ' ' + isnull(MidName,'')
           	from dbo.bPREH with (nolock) where PRCo = @prco and Employee = @employee
           	end
   
       	if @paymethod = 'E' -- EFT
           	begin
           	select @cmtranstype = 4
           	select @payee = null
           	select @desc = 'Direct Deposit'
           	end
   
       	if @batchmth is null or @batchmth <> @mth
           	begin
           	-- add a Batch for each month updated in GL
           	exec @batchid = bspHQBCInsert @prco, @mth, 'PR Update', 'bPRSQ', 'N', 'N', @prgroup, @prenddate, @errmsg output
           	if @batchid = 0
   	       		begin
                       	select @errmsg = 'Unable to add a Batch to update Payments!', @rcode = 1
   		   	goto bspexit
   	       		end
   
              	--- update batch status as 'posting in progress'
              	update dbo.bHQBC set Status = 4, DatePosted = @postdate
               	where Co = @prco and Mth = @mth and BatchId = @batchid
   
           	select @batchmth = @mth
           	end
   
   	begin transaction
   
   	-- check for EFT update -  if exists, already validated
   	if @paymethod = 'E'
   		begin
   		update dbo.bCMDT set Amount = Amount - @netpay	-- EFT amounts updated as negatives
   		where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 4
   			and CMRef = @cmref and CMRefSeq = @cmrefseq
   		if @@rowcount = 1 goto update_PRPay
   		end
   
   	-- get next available transaction # for CM Detail
   	exec @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @errmsg output
   	if @cmtrans = 0
   		begin
     	    	select @errmsg = 'Unable to get another transaction # for CM Detail!', @rcode = 1
           	goto CM_posting_error
     	    	end
   	insert dbo.bCMDT (CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate, PostedDate,
    	     Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, Payee, GLCo, CMGLAcct, Void, Purge)
    	values (@cmco, @mth, @cmtrans, @cmacct, @cmtranstype, @prco, 'PR Update', @paiddate, @postdate,
           	@desc, -(@netpay), 0, @batchid, @cmref, @cmrefseq, @payee, @glco, @cmglacct, 'N', 'N')
       	if @@rowcount = 0
   	    	begin
   	    	select @errmsg = 'Unable to add CM Detail entry!', @rcode = 1
   	    	goto CM_posting_error
     	    	end
   
       	update_PRPay:   -- update PR Payment History
           	if @paymethod = 'C' select @eftseq = 0
           	insert dbo.bPRPH (PRCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, PRGroup, PREndDate, Employee,
               		PaySeq, ChkType, PaidDate, PaidMth, Hours, Earnings, Dedns, PaidAmt, NonTrueAmt, Void, VoidMemo, Purge)
           	values(@prco, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq, @prgroup, @prenddate, @employee,
               		@payseq, @chktype, @paiddate, @mth, @totalhours, @totalearns, @totaldedns, @netpay, @nontrueamt, 'N', null, 'N')
           	if @@rowcount = 0
               		begin
   	        	select @errmsg = 'Unable to add PR Payment History entry!', @rcode = 1
   	        	goto CM_posting_error
     	        	end
           	if @paymethod = 'E'     -- add EFT Direct Deposit History
               		begin
               		insert dbo.bPRDH (PRCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, DistSeq, RoutingId, BankAcct, Type, Amt)
               		select @prco, @cmco, @cmacct, 'E', @cmref, @cmrefseq, @eftseq, DistSeq, RoutingId, BankAcct, Type, Amt
               		from dbo.bPRDS with (nolock)
               		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
                   		and PaySeq = @payseq
               		end
   
       		-- update CM interface flag for Employee Payment Sequence
       		update dbo.bPRSQ set CMInterface = 'Y'
       		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
                   	and PaySeq = @payseq
       		if @@rowcount = 0
           		begin
   	    		select @errmsg = 'Unable to update CM interface flag in PR Sequence Control!', @rcode = 1
   	    		goto CM_posting_error
   
     	    		end
   
       	commit transaction
      	goto next_EmplSeq
   
       	CM_posting_error:
         		rollback transaction
        		goto bspexit
   
   	end_EmplSeq:
   		close bcEmplSeq
   		deallocate bcEmplSeq
   		select @openEmplSeq = 0
   
           -- close the Batch Control entries
           update dbo.bHQBC set Status = 5, DateClosed = getdate()
   	    where Co = @prco and  TableName = 'bPRSQ' and PRGroup = @prgroup and PREndDate = @prenddate
   
   -- Update Voids
   
   select @batchmth = null
   
   -- cursor on PR Void Payments table
   declare bcVoid cursor for
   select CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType, PaidDate, PaidMth,
       	Employee, PaidAmt, VoidMemo, Reuse, PaySeq, Hours, Earnings, Dedns
   from dbo.bPRVP with (nolock)
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   order by PaidMth, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq
   
   open bcVoid
   select @openVoid = 1
   
   next_Void:
   	fetch next from bcVoid into @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq,
           	@chktype, @paiddate, @mth, @employee, @paidamt, @voidmemo, @reuse, @payseq, @hours, @earns, @dedns
       	if @@fetch_status <> 0 goto end_Void
   
       	-- get CM GL Account    -- already validated
       	select @glco = GLCo, @cmglacct = GLAcct
       	from dbo.bCMAC with (nolock)
       	where CMCo = @cmco and CMAcct = @cmacct
   
       	-- get Employee name for CM description
           select @payee = convert(varchar(20),@employee) --#26490
       	select @desc = isnull(LastName,'') + ', ' + isnull(FirstName,'') + ' ' + isnull(MidName,'')
           from dbo.bPREH with (nolock) where PRCo = @prco and Employee = @employee
   
       	if @batchmth is null or @batchmth <> @mth
           	begin
           	-- add a Batch for each month updated in GL
           	exec @batchid = bspHQBCInsert @prco, @mth, 'PR Update', 'bPRVP', 'N', 'N', @prgroup, @prenddate, @errmsg output
           	if @batchid = 0
   	       		begin
   		   	      select @errmsg = 'Unable to add a Batch to update Void Payments!', @rcode = 1
   		   	      goto bspexit
   	      		end
               --- update batch status as 'posting in progress'
               update dbo.bHQBC set Status = 4, DatePosted = @postdate
                where Co = @prco and Mth = @mth and BatchId = @batchid
   
           	select @batchmth = @mth
           	end
   
       	begin transaction
   
       	if @reuse = 'N'     -- Checks only -  # will not be reused - record as void
           	begin
           	-- update CM Detail
           	update dbo.bCMDT set Void = 'Y'
           	where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 1  -- checks only
               		and CMRef = @cmref and CMRefSeq = @cmrefseq
           	if @@rowcount = 0
               		begin
               		-- get next available transaction # for CM Detail
   	        	exec @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @errmsg output
   	        	if @cmtrans = 0
                   	begin
   	  	        	select @errmsg = 'Unable to get another transaction # for CM Detail!', @rcode = 1
   	            		goto Void_posting_error
     	            		end
               	insert dbo.bCMDT (CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate, PostedDate,
    	            	Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, Payee, GLCo, CMGLAcct, Void, Purge)
               	values (@cmco, @mth, @cmtrans, @cmacct, 1, @prco, 'PR Update', @paiddate, @postdate,
                   	@desc, -(@paidamt), 0, @batchid, @cmref, @cmrefseq, @payee, @glco, @cmglacct, 'Y', 'N')
              	if @@rowcount = 0
   	            	begin
   	            	select @errmsg = 'Unable to add CM Detail entry for voided check!', @rcode = 1
   	            	goto Void_posting_error
     	            	end
               	end
   
           -- update PR Payment History
           update dbo.bPRPH set Void = 'Y', VoidMemo = @voidmemo
           where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
           	and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
           if @@rowcount = 0
           	begin
               	insert dbo.bPRPH (PRCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, PRGroup, PREndDate, Employee,
               		PaySeq, ChkType, PaidDate, PaidMth, Hours, Earnings, Dedns, PaidAmt, NonTrueAmt, Void, VoidMemo, Purge)
               	values(@prco, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq, @prgroup, @prenddate,
        	@employee, @payseq, @chktype, @paiddate, @mth, @hours, @earns, @dedns, @paidamt, 0, 'Y', @voidmemo, 'N')
               	if @@rowcount = 0
   	            	begin
   	            	select @errmsg = 'Unable to add PR Payment History for voided check!', @rcode = 1
   	            	goto Void_posting_error
     	           	end
               	end
           end
   
   	if @reuse = 'Y'     -- can be Check or EFT - already validated for matching info, not cleared, etc.
           	begin
           	if @paymethod = 'C'
               		begin
               		-- if exists in CM Detail, remove it
               		delete dbo.bCMDT
               		where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 1    -- Check
                   		and CMRef = @cmref and CMRefSeq = @cmrefseq
   
               		-- if exists in PR Payment History, remove it
              		delete dbo.bPRPH
               		where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
                   		and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
               		end
           	if @paymethod = 'E'
               		begin
               		-- if exists in CM Detail, back out paid amt from EFT total
               		update dbo.bCMDT set Amount = Amount + @paidamt   -- amounts stored as negative in CM
               		where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 4    -- EFT
                  			and CMRef = @cmref and CMRefSeq = @cmrefseq
           		-- if exists in PR Payment History, remove it
               		delete dbo.bPRPH
               		where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
                   		and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
               		-- if exists in PR Deposit History, remove it
               		delete dbo.bPRDH
               		where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
                   		and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
               		end
           	end
   
       	-- remove PR Void entry
       	delete dbo.bPRVP
       	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and CMCo = @cmco
           	and CMAcct = @cmacct and PayMethod = @paymethod and CMRef = @cmref and CMRefSeq = @cmrefseq
           	and EFTSeq = @eftseq
       	if @@rowcount = 0
           	begin
           	select @errmsg = 'Unable to remove PR Void Payment entry!', @rcode = 1
           	goto Void_posting_error
           	end
   
       	commit transaction
      	goto next_Void
   
       	Void_posting_error:
         		rollback transaction
        		goto bspexit
   
   	end_Void:
   		close bcVoid
   		deallocate bcVoid
   		select @openVoid = 0
   
           -- close the Batch Control entries
           update dbo.bHQBC set Status = 5, DateClosed = getdate()
   	    where Co = @prco and  TableName = 'bPRVP' and PRGroup = @prgroup and PREndDate = @prenddate
   
   
   bspexit:
       if @openEmplSeq = 1
           begin
           close bcEmplSeq
   		deallocate bcEmplSeq
           end
       if @openVoid = 1
           begin
           close bcVoid
    		deallocate bcVoid
           end
   
       --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdatePostCM]'
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdatePostCM] TO [public]
GO
