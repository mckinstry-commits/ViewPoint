SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRCheckReplace]
/***********************************************************
* CREATED BY: GG 09/11/01
* MODIFIED BY: GH 12/18/01 Added 'set HQ Batch status to 5 (posted)' code
*				GG 5/29/02 - #16988 - update EFTSeq as null with replacement check
*				EN 10/7/02 - issue 18877 change double quotes to single
*				EN 2/4/04 - issue 20974 use different CM Ref validation stored procedure
*
* USAGE:
* Called by the PR Check Replacement program to void old payment information
* and update new check values.  Makes on-line updates to bPRSQ, bPRPH, and bCMDT.
*
* INPUT PARAMETERS
*   @prco		    PR Co#
*   @prgroup		PR Group being paid
*   @prenddate		Pay Period ending date
*   @employee		Employee number
*   @payseq		Payment Seq#
*   @voidmemo		Void Memo
*   @chktype		Check Type, 'C' computer or 'M' manual
*   @cmref			CM Reference, Check #
*   @cmrefseq		CM Reference Seq#
*
* OUTPUT PARAMETERS
*   @msg      		error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
*******************************************************************/
 	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @employee bEmployee = null,
 	 @payseq tinyint = null, @voidmemo bDesc = null, @chktype char(1) = null, @cmref bCMRef = null,
 	 @cmrefseq tinyint = null, @msg varchar(255) output)
     
     as
     
     set nocount on
     
     declare @rcode tinyint, @status tinyint, @glinterface bYN, @cmco bCompany, @cmacct bCMAcct,
     	@xpaymethod char(1), @xcmref bCMRef, @xcmrefseq tinyint, @eftseq smallint, @paiddate bDate,
     	@paidmth bMonth, @hours bHrs, @earnings bDollar, @dedns bDollar, @netpay bDollar, @void bYN,
     	@cmtrans bTrans, @stmtdate bDate, @batchid bBatchID, @glco bCompany, @cmglacct bGLAcct,
     	@desc bDesc
     
     select @rcode = 0, @msg = 'Cannot replace this Employee''s payment information.' + char(13) + char(10)
     
     -- validate input parameters
     if @prco is null or @prgroup is null or @prenddate is null or @employee is null or @payseq is null
     	or @cmref is null or @cmrefseq is null
     	begin
     	select @msg = isnull(@msg,'') + 'Must provide PR Co#, PR Group, PR End Date, Employee, Pay Seq#, CM Reference, and Ref Seq#.', @rcode = 1
     	goto bspexit
     	end
     
     -- validate Pay Period
     select @status = Status, @glinterface = GLInterface
     from dbo.bPRPC with (nolock)
     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
     if @@rowcount = 0
     	begin
         select @msg = isnull(@msg,'') + 'Pay Period does not exist!', @rcode = 1
         goto bspexit
         end
     if @status <> 1
         begin
         select @msg = isnull(@msg,'') + 'Pay Period must be closed!', @rcode = 1
         goto bspexit
         end
     if @glinterface = 'N'
     	begin
     	select @msg = isnull(@msg,'') + 'Final GL/CM/Employee Accumulation update has not been run!', @rcode = 1
     	goto bspexit
     	end
     -- validate Employee payment info
     select @cmco = CMCo, @cmacct = CMAcct, @xpaymethod = PayMethod, @xcmref = CMRef, @xcmrefseq = CMRefSeq,
     	@eftseq = EFTSeq, @paiddate = PaidDate, @paidmth = PaidMth, @hours = Hours, @earnings = Earnings,
     	@dedns = Dedns
     from dbo.bPRSQ with (nolock)
     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     	and PaySeq = @payseq
     if @@rowcount = 0
     	begin
     	select @msg = isnull(@msg,'') + 'Employee Sequence Control entry not found!', @rcode = 1
     	goto bspexit
     	end
     if @xpaymethod not in ('C','E')
     	begin
     	select @msg = 'Old Payment method must be Check or EFT!', @rcode = 1
     	goto bspexit
     	end
     -- validate old payment in PR
     select @void = Void
     from dbo.bPRPH with (nolock)
     where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @xpaymethod
     	and CMRef = @xcmref and CMRefSeq = @xcmrefseq and EFTSeq = isnull(@eftseq,0)
     if @@rowcount = 0
     	begin
     	select @msg = isnull(@msg,'') + 'Old payment information not found in PR Payment History.',@rcode = 1
     	goto bspexit
     	end
     if @void = 'Y'
     	begin
     	select @msg = isnull(@msg,'') + 'Old payment information has already been voided.',@rcode = 1
     	goto bspexit
     	end
     
     select @netpay = @earnings - @dedns	-- amount paid
     
     -- validate old payment in CM
     select @cmtrans = CMTrans, @stmtdate = StmtDate, @void = Void
     from dbo.bCMDT with (nolock)
     where CMCo = @cmco and Mth = @paidmth and CMAcct = @cmacct
     	and CMTransType = (case @xpaymethod when 'E' then 4 else 1 end)
     	and CMRef = @xcmref and CMRefSeq = @xcmrefseq
     if @@rowcount = 0
     	begin
     	select @msg = isnull(@msg,'') + 'Old payment information not found in CM Detail.',@rcode = 1
     	goto bspexit
     	end
     if @void = 'Y'
     	begin
     	select @msg = isnull(@msg,'') + 'Old payment information has already been voided in CM.',@rcode = 1
     	goto bspexit
     	end
     if @stmtdate is not null
     	begin
     	select @msg = isnull(@msg,'') + 'Old payment has already been cleared in CM.',@rcode = 1
     	goto bspexit
     	end
     
     -- validate new CM Reference and Ref Seq#
     exec @rcode = bspPRCMRefValUniqueForReplace @prco, @prgroup, @prenddate, @employee, @payseq, @cmco, @cmacct, @cmref, @cmrefseq, @msg output
     if @rcode <> 0 goto bspexit
     	
     -- passed necessary validation, start transaction for on-line update
     begin transaction
     
     -- add a Batch Control entry, recorded with both old and bCMDT entries
     exec @batchid = bspHQBCInsert @prco, @paidmth, 'PR ChkRepl', 'bPRSQ', 'N', 'N', @prgroup, @prenddate, @msg output
     if @batchid = 0
     	begin
     	select @msg = isnull(@msg,'') + 'Unable to add a Batch Control entry!'
     	goto update_error
     	end
     --- update batch status as 'posting in progress'
     update dbo.bHQBC
     set Status = 4, DatePosted = convert(varchar,getdate(),1)
     where Co = @prco and Mth = @paidmth and BatchId = @batchid
     if @@rowcount <> 1
     	begin
     	select @msg = isnull(@msg,'') + 'Unable to update Batch Control entry!'
     	goto update_error
     	end
     
     -- if old payment was check, void existing CM Detail
     if @xpaymethod = 'C'
     	begin
         update dbo.bCMDT set Void = 'Y', BatchId = @batchid
         where CMCo = @cmco and Mth = @paidmth and CMTrans = @cmtrans
         if @@rowcount = 0
     		begin
     		select @msg = isnull(@msg,'') + 'Unable to void existing payment information in CM Detail.'
     		goto update_error
     		end 
     	end
     -- if old payment was EFT, back out paid amount from CM Detail
     if @xpaymethod = 'E'
     	begin
     	update dbo.bCMDT set Amount = Amount + @netpay, BatchId = @batchid	-- backout amount from total EFT (sign is reversed)
     	where CMCo = @cmco and Mth = @paidmth and CMTrans = @cmtrans
         if @@rowcount = 0
     		begin
     		select @msg = isnull(@msg,'') + 'Unable to update existing EFT information in CM Detail.'
     		goto update_error
     		end
     	end
     	
     -- get CM GL Account    
     select @glco = GLCo, @cmglacct = GLAcct
     from dbo.bCMAC with (nolock) where CMCo = @cmco and CMAcct = @cmacct
     -- get Employee name for CM description
     select @desc = isnull(LastName,'') + ', ' + isnull(FirstName,'') + ' ' + isnull(MidName,'')
     from dbo.bPREH with (nolock) where PRCo = @prco and Employee = @employee
     
     -- get next available transaction # for CM Detail
     exec @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @paidmth, @msg output
     if @cmtrans = 0
     	begin
     	select @msg = isnull(@msg,'') + 'Unable to get another transaction # for CM Detail!'
     	goto update_error
       	end
     -- add CM Detail for replacement check
     insert dbo.bCMDT (CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate, PostedDate,
     	Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, Payee, GLCo, CMGLAcct, Void, Purge)
     values (@cmco, @paidmth, @cmtrans, @cmacct, 1, @prco, 'PR ChkRepl', @paiddate, convert(varchar,getdate(),1),
         @desc, -(@netpay), 0, @batchid, @cmref, @cmrefseq, convert(varchar,@employee), @glco, @cmglacct, 'N', 'N')
     if @@rowcount = 0
     	begin
     	select @msg = isnull(@msg,'') + 'Unable to add CM Detail entry for replacement check!'
     	goto update_error
       	end
     
     -- void existing entry in PR Payment History
     update dbo.bPRPH set Void = 'Y', VoidMemo = @voidmemo
     where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @xpaymethod
     	and CMRef = @xcmref and CMRefSeq = @xcmrefseq and EFTSeq = isnull(@eftseq,0)
     if @@rowcount = 0
         begin
        	select @msg = isnull(@msg,'') + 'Unable to void old entry in PR Payment History!'
     	goto update_error
       	end
     -- if old payment was EFT, remove any direct deposit detail
     if @xpaymethod = 'E'
     	delete dbo.bPRDH 
     	where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @xpaymethod
     		and CMRef = @xcmref and CMRefSeq = @xcmrefseq and EFTSeq = isnull(@eftseq,0)
     
     -- add PR Payment History entry for replacement check
     insert dbo.bPRPH (PRCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, PRGroup, PREndDate, Employee,
     	PaySeq, ChkType, PaidDate, PaidMth, Hours, Earnings, Dedns, PaidAmt, NonTrueAmt, Void, Purge)
     select @prco, @cmco, @cmacct, 'C', @cmref, @cmrefseq, 0, @prgroup, @prenddate, @employee,
     	@payseq, @chktype, @paiddate, @paidmth, Hours, Earnings, Dedns, PaidAmt, NonTrueAmt,'N','N'
     from dbo.bPRPH with (nolock)
     where PRCo = @prco and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @xpaymethod
     	and CMRef = @xcmref and CMRefSeq = @xcmrefseq and EFTSeq = isnull(@eftseq,0)
     if @@rowcount = 0
         begin
     	select @msg = isnull(@msg,'') + 'Unable to add PR Payment History entry for replacement check!'
     	goto update_error
       	end
     
     -- update payment information in PR Sequence Control
     update dbo.bPRSQ
     set CMRef = @cmref, CMRefSeq = @cmrefseq, EFTSeq = null, PayMethod = 'C', ChkType = @chktype
     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
     	and Employee = @employee and PaySeq = @payseq
     if @@rowcount <> 1
     	begin
     	select @msg = isnull(@msg,'') + 'Unable to update Check information in PR Sequence control!'
     	goto update_error
     	end
     
    /* set HQ Batch status to 5 (posted) */
    update dbo.bHQBC
    set Status = 5, DateClosed = getdate()
    where Co = @prco and Mth = @paidmth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @msg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
     
    commit transaction	-- all updates successfully completed
    
    goto bspexit
    
    update_error:	-- error occurred during the update, rollback everything 
    	rollback transaction
    	select @rcode = 1
    	goto bspexit
         
    bspexit:
    	--if @rcode = 1 select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspPRCheckReplace]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCheckReplace] TO [public]
GO
