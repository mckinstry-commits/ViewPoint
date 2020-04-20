SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRCheckVoid]
  /****************************************************************************
  * CREATED: EN 6/18/98
  * MODIFIED: GG 8/13/98
  *			EN 1/18/05 issue 26490  return error if PRVP entry already exists instructing user to run Ledger Interface before voiding
  *			GG 10/03/05 - #29555 - rewrote validation, added check for cleared CM entries
  *
  * USAGE:
  * 	Called by PR Employee Seq Control to clears payment information from bPRSQ for a 
  *	specific PRCo/PRGroup/PREndDate/Employee/PaySeq.
  *	Adds PR Void entry for true voids and payments already updated to CM
  *
  *  INPUT PARAMETERS
  *   @PRCo		PR Company
  *   @PRGroup	PR Group
  *   @PREndDate	PR period ending date
  *   @Employee	Employee number
  *   @PaySeq		Payment sequence number
  *   @VoidMemo  	Void Memo to use in creating PRVP entry
  *   @Reuse		Reuse flag to use in creating PRVP entry
  *
  * OUTPUT PARAMETERS
  *   @msg      error message if error occurs
  * RETURN VALUE
  *   0         success
  *   1         Failure
  ****************************************************************************/
    (@PRCo bCompany, @PRGroup bGroup, @PREndDate bDate, @Employee bEmployee,
     @PaySeq tinyint, @VoidMemo bDesc, @Reuse bYN, @msg varchar(100) output)
    as
    
  set nocount on
    
  declare @rcode tinyint, @cmco bCompany, @cmacct bCMAcct, @paymethod varchar(1),
  	@cmref bCMRef, @cmrefseq tinyint, @eftseq smallint, @chktype varchar(1), @paiddate bDate,
  	@paidmth bMonth, @hours bHrs, @earnings bDollar, @dedns bDollar, @cminterface bYN, @stmtdate bDate
    
  select @rcode = 0
    
  /* validate inputs */
  if @Reuse is null or (@Reuse <> 'Y' and @Reuse <> 'N')
  	begin
    	select @msg = 'Reuse flag must be ''Y'' or ''N''', @rcode = 1
    	goto bspexit
    	end
  
  -- get payment info from Employee Seq Control
  select @cmco = CMCo, @cmacct = CMAcct, @paymethod = PayMethod, @cmref = CMRef, @cmrefseq = CMRefSeq,
  	@eftseq = EFTSeq, @chktype = ChkType, @paiddate = PaidDate, @paidmth = PaidMth, @hours = Hours,
    	@earnings = Earnings, @dedns = Dedns, @cminterface = CMInterface
  from dbo.bPRSQ
  where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate
  	and Employee=@Employee and PaySeq=@PaySeq
  if @@rowcount = 0
  	begin
    	select @msg = 'Employee/Pay Sequence Control entry not found!', @rcode = 1
    	goto bspexit
    	end
  
  -- validate payment info
  if @paymethod = 'X'
  	begin
  	select @msg = 'Employee/Pay Sequence is marked as ''X - No Pay'', there is nothing to void!', @rcode = 1
  	goto bspexit
  	end
  if @cmref is null
  	begin
  	select @msg = 'Employee/Pay Sequence entry has not been paid!', @rcode = 1
  	goto bspexit
  	end
  if @cminterface = 'Y'	-- already updated to CM
  	begin
  	select @stmtdate = StmtDate
  	from dbo.bCMDT with (nolock)
  	where CMCo = @cmco and CMAcct = @cmacct and Mth = @paidmth
  		and CMTransType = (case @paymethod when 'E' then 4 when 'C' then 1 else null end)
  		and CMRef = @cmref and CMRefSeq = @cmrefseq
  	if @@rowcount = 0
  		begin
  		select @msg = 'Payment entry missing from CM!', @rcode = 1
  		goto bspexit
  		end
  	if @stmtdate is not null
  		begin
  		select @msg = 'Payment has already by cleared in CM!', @rcode = 1
  		goto bspexit
  		end
  	end
  
  begin transaction	-- link the updates to bPRVP and bPRSQ
  
  if @Reuse = 'N' or @cminterface = 'Y'	-- PR Void entry needed for voids and previously interfaced payments
  	begin
   	if exists (select top 1 1 from dbo.bPRVP where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate and
   			CMCo=@cmco and CMAcct=@cmacct and PayMethod=@paymethod and CMRef=@cmref and CMRefSeq=@cmrefseq and EFTSeq=isnull(@eftseq,0))
   		begin
   		select @msg = 'An unprocessed void already exists for this number, must run the PR Ledger Update to Cash Management first.', @rcode = 1
   		rollback transaction
  		goto bspexit
   		end
  	-- add PR Void entry
    	insert bPRVP (PRCo, PRGroup, PREndDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType,
  		PaidDate, PaidMth, Employee, PaidAmt, VoidMemo, Reuse, PaySeq, Hours, Earnings, Dedns)
    	values (@PRCo, @PRGroup, @PREndDate, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, isnull(@eftseq,0), @chktype,
  		@paiddate, @paidmth, @Employee, (@earnings - @dedns), @VoidMemo, @Reuse, @PaySeq, @hours, @earnings, @dedns)
  	if @@error <> 0 
  		begin
  		select @msg = 'Unable to add PR Void entry', @rcode = 1
  		rollback transaction
  		goto bspexit
  		end
  	end
  
  -- clear payment info in PRSQ 
  update dbo.bPRSQ
  set CMRef=null, CMRefSeq=null, EFTSeq=null, PaidDate=null, PaidMth=null, Hours=0,
    	Earnings=0, Dedns=0, CMInterface='N'
  where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDate and Employee=@Employee and PaySeq=@PaySeq
  if @@rowcount <> 1
  	begin
    	select @msg = 'Unable to remove payment information from Employee/Pay Sequence. Void canceled!', @rcode = 1
    	rollback transaction
  	goto bspexit
    	end
  
  commit transaction	-- successful update 
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCheckVoid] TO [public]
GO
