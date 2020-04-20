SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREFTProcess    Script Date: 8/28/99 9:35:31 AM ******/
   CREATE      procedure [dbo].[bspPREFTProcess]
   /***********************************************************
    * CREATED BY: EN 4/24/98
    * MODIFIED By: GG 07/02/99
    *             	GG 5/23/00 - fix to reset bPRSQ.CMInterface flag when EFT is voided
    *             	GG 01/29/01 - removed bPRSQ.InUse
    *             	GG 06/12/01 - added isnull to total earnings #13747
    *				GG 01/18/02 - #15810 - make sure distributions equal net pay, cleanup to remove extra cursors
    *				GG 07/25/02 - #17998 - removed reload param and logic, performed in bspPREFTClear 
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 9/19/05 - issue 29837 update bPRSQ_CMAcct from bPRGP in case it has changed since bPRSQ entry was first inserted
    *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
    *				MV 08/28/2012 - TK-17452 include Payback Amt in deduction amounts from PRDT
    *
    * USAGE:
    * 	Called by PR EFT Download form to assign EFT payment info to eligible
    *	PR Employee Pay Sequence entries.
    *
    * INPUT PARAMETERS
    *  @PRCo			PR company number
    *  @PRGroup		Group number being processed
    *  @PREndDate		Period ending date
    *  @EffectiveDate  Date of payment
    *  @PaidMth   		Month of payment
    *  @PaySeq			Payment sequence # (optional)
    *  @CMCo 			CM Company number
    *  @CMAcct			CM Account number
    *  @CMRef 			CM Reference number
    *
    * OUTPUT PARAMETERS
    *   @msg      		error message if error occurs
    *
    * RETURN VALUE
    *  0   	success
    *  1   	fail
    *	5 		one or more Employee/PaySeqs skipped during processing
    *******************************************************************/
   	(@PRCo bCompany = null, @PRGroup bGroup = null, @PREndDate bDate = null,
   	 @EffectiveDate bDate = null, @PaidMth bMonth = null, @PaySeq tinyint = null,
   	 @CMCo bCompany = null, @CMAcct bCMAcct = null, @CMRef bCMRef = null,
   	 @msg varchar(255) output)
   
   as
   set nocount on
   --#142350 - renaming @cmacct
	DECLARE @rcode tinyint,
			@eftseq smallint,
			@employee bEmployee,
			@pseq tinyint,
			@processed bYN,
			@hours bHrs,
			@earnings bDollar,
			@dedns bDollar,
			@dist bDollar,
			@opencursor tinyint,
			@status tinyint,
			@CMAccount bCMAcct
		    
   select @rcode = 0, @opencursor = 0, @eftseq = 0
   
   /* validate inputs */
   if @PRCo is null
   	begin
       select @msg = 'Missing PR company number!', @rcode = 1
       goto bspexit
       end
   if @PRGroup is null
    	begin
    	select @msg = 'Missing PR Group!', @rcode = 1
    	goto bspexit
    	end
   if @PREndDate is null
    	begin
    	select @msg = 'Missing Pay Period Ending Date!', @rcode = 1
    	goto bspexit
    	end
   select @status = Status
   from bPRPC
   where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
   if @@rowcount = 0
    	begin
    	select @msg = 'Pay Period does not exist!', @rcode = 1
    	goto bspexit
    	end
   if @status <> 0
   	begin
    	select @msg = 'Pay Period must be open!', @rcode = 1
    	goto bspexit
    	end
   if @EffectiveDate is null
    	begin
    	select @msg = 'Missing paid date!', @rcode = 1
    	goto bspexit
    	end
   if @PaidMth is null
    	begin
    	select @msg = 'Missing paid month!', @rcode = 1
    	goto bspexit
    	end
   if @CMCo is null
    	begin
    	select @msg = 'Missing CM company number!', @rcode = 1
    	goto bspexit
    	end
   if @CMAcct is null
    	begin
    	select @msg = 'Missing CM Account number!', @rcode = 1
    	goto bspexit
    	end
   if @CMRef is null
    	begin
    	select @msg = 'Missing CM Reference number!', @rcode = 1
    	goto bspexit
    	end
   
   --#29837 get CM Account for the PR Group
   select @CMAccount = CMAcct
   from dbo.bPRGR with (nolock)
   where PRCo = @PRCo and PRGroup = @PRGroup
   if @@rowcount = 0
      begin
   	select @msg = 'Invalid PR Group!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate CM Reference to be used for EFT
   exec @rcode = bspPRCMRefValEFT @CMCo, @CMAcct, @CMRef, @msg output
   if @rcode <> 0 goto bspexit
   
   -- use a cursor to process each unpaid PR Employee Pay Sequence
   declare bcPRSQ cursor for
   select Employee, PaySeq, Processed
   from bPRSQ
   where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
   	and PaySeq = isnull(@PaySeq,PaySeq) and CMRef is null and PayMethod = 'E'
   order by Employee, PaySeq
   
   /* open cursor */
   open bcPRSQ
   select @opencursor = 1
   
   /* loop through PRSQ */
   PRSQ_loop:
   	fetch next from bcPRSQ into @employee, @pseq, @processed
     
   	if @@fetch_status <> 0 goto bspexit
   
   	-- skip if Processing is needed
   	if @processed = 'N'
   		begin
   		select @rcode = 5
   		goto PRSQ_loop
   		end
   	-- skip if unposted timecards exist
   	if exists(select 1 from bHQBC c
   			  join bPRTB b on c.Co = b.Co and c.Mth = b.Mth	and c.BatchId = b.BatchId
   			  where c.Co = @PRCo and c.PRGroup = @PRGroup and c.PREndDate = @PREndDate
   					and b.Employee = @employee and b.PaySeq = @pseq)
   		begin
   		select @rcode = 5
   		goto PRSQ_loop
   		end
   
   	-- accumulate total hours and earnings 
     	select @hours = isnull(sum(Hours),0), @earnings = isnull(sum(Amount),0)
     	from bPRDT
     	where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
   		and Employee = @employee and PaySeq = @pseq and EDLType = 'E'
   	-- accumulate total deductions
     	SELECT @dedns = isnull(sum(case UseOver when 'Y' then OverAmt else Amount end),0)
     		+ ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0) -- TK-17452
     	FROM dbo.bPRDT
     	WHERE PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
   			AND Employee = @employee and PaySeq = @pseq and EDLType = 'D'
   
   	-- skip negative or zero payments with no earnings or deductions
     	if @earnings - @dedns < 0 or (@earnings - @dedns = 0 and (@earnings = 0 or @dedns = 0)) goto PRSQ_loop
   
   	-- accumulate direct deposit distributions
   	select @dist = isnull(sum(Amt),0)
   	from bPRDS
   	where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
       	and PaySeq = @pseq
   	-- skip if distributions do not equal net pay
   	if @dist <> (@earnings - @dedns)
   		begin
   		select @rcode = 5
   		goto PRSQ_loop
   		end
   
   	-- ok to assign EFT and update payment info in PR Employee Sequence Control 	 
    	select @eftseq = @eftseq + 1
    	 
   	update bPRSQ
    	set CMAcct = @CMAccount, CMRef = @CMRef, CMRefSeq = 0, EFTSeq = @eftseq, PaidDate = @EffectiveDate, --#29837
   		PaidMth = @PaidMth, Hours = @hours, Earnings = @earnings, Dedns = @dedns
    	where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
   		and PaySeq = @pseq
   	if @@rowcount <> 1
   		begin
   		select @msg = 'Unable to update payment info in PR Employee Sequence Control!', @rcode = 1
   		goto bspexit
   		end
   
   	goto PRSQ_loop
   
   bspexit:
   	if @opencursor = 1
    		begin
    		close bcPRSQ
    		deallocate bcPRSQ
    		end
    	
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREFTProcess] TO [public]
GO
