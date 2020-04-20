SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREFTProcessCheck    Script Date: 8/28/99 9:35:31 AM ******/
   CREATE       procedure [dbo].[bspPREFTProcessCheck]
   /***********************************************************
    * CREATED BY: DANF 09/19/01
    * MODIFIED By: GG 10/03/01 - #13339 - changed to search for unprocessed Employees only
    *				GG 01/18/02 - #15810 - added PaySeq and Reload parameters, check sum of distributions equals net pay
    *				GG 07/25/02 - #17998 - removed reload param and logic, performed in bspPREFTClear
    *				MV 08/28/2012 - TK-17452 include Payback Amt in deduction amounts from PRDT
    *
    * USAGE:
    * Called from the PR EFT Download form prior to assigning CMRef and EFTSeq to
    * Employee/Pay Seqs flagged for EFT payment.
    *
    * INPUT PARAMETERS
    *  @PRCo		PR company number
    *  @PRGroup		Group number being processed
    *  @PREndDate		Period ending date
    *	@PaySeq			Payment Sequence restriction, null if all
    *
    * OUTPUT PARAMETERS
    *   @msg      		error message if error occurs
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *******************************************************************/
   	(@PRCo bCompany = null, @PRGroup bGroup = null, @PREndDate bDate = null,
   	 @PaySeq tinyint = null, @msg varchar(255) output)
    
   as
   
   set nocount on
   
   declare @rcode tinyint, @opencursor tinyint, @employee bEmployee, @pseq tinyint,
   	@processed bYN, @earnings bDollar, @dedns bDollar, @dist bDollar, @cnt int,
   	@status tinyint, @msgstart varchar(100)
   
   select @rcode = 0, @opencursor = 0, @cnt = 0
   
   /* validate inputs */
   if @PRCo is null
   	begin
       select @msg = 'Missing PR company number!', @rcode = 1
       goto bspexit
       end
   if @PRGroup is null
    	begin
    	select @msg = 'Missing PR group!', @rcode = 1
    	goto bspexit
    	end
   if @PREndDate is null
    	begin
    	select @msg = 'Missing PR Period Ending Date!', @rcode = 1
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
    	select @msg = 'Pay Period is closed!', @rcode = 1
    	goto bspexit
    	end
   if @PaySeq is not null
   	begin
   	if not exists(select 1 from bPRPS where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
   			and PaySeq = @PaySeq)
   		begin
    		select @msg = 'Payment Sequence does not exist for this Pay Period!', @rcode = 1
    		goto bspexit
    		end
   	end
   	
   -- create a cursor to inspect each Employee to be paid by EFT
   declare bcPRSQ cursor for
   select Employee, PaySeq, Processed
   from bPRSQ
   where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate
    	and PaySeq = isnull(@PaySeq,PaySeq) and PayMethod = 'E'	and CMRef is null 
    	
   open bcPRSQ
   select @opencursor = 1
   
   PRSQ_loop:
   	fetch next from bcPRSQ into @employee, @pseq, @processed
     
   	if @@fetch_status <> 0 	goto bspexit
   
   	select @msgstart = 'Employee: ' + convert(varchar,@employee) + ' Pay Seq: ' + convert(varchar,@pseq)
   	if @processed = 'N'
   		begin
   		select @msg = @msgstart + ' needs to be processed.', @rcode = 1
   		goto bspexit
   		end
   	if exists(select 1 from bHQBC c
   			  join bPRTB b on c.Co = b.Co and c.Mth = b.Mth	and c.BatchId = b.BatchId
   			  where c.Co = @PRCo and c.PRGroup = @PRGroup and c.PREndDate = @PREndDate
   					and b.Employee = @employee and b.PaySeq = @pseq)
   		begin
   		select @msg = @msgstart + ' has unposted timecards.', @rcode = 1
   		goto bspexit
   		end
   
   	-- check that net pay equals distribution total
   	select @earnings = isnull(sum(Amount),0)
     	from bPRDT
     	where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
       	and PaySeq = @pseq and EDLType = 'E'
   
     	select @dedns = isnull(sum( case UseOver when 'Y' then OverAmt else Amount end),0)
     		+ ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0) -- TK-17452
     	from bPRDT
     	where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
       	and PaySeq = @pseq and EDLType = 'D'
   
   	-- skip if not eligible for payment
   	if @earnings - @dedns < 0 or (@earnings - @dedns = 0 and (@earnings = 0 or @dedns = 0)) goto PRSQ_loop
   
   	select @dist = isnull(sum(Amt),0)
   	from bPRDS
   	where PRCo = @PRCo and PRGroup = @PRGroup and PREndDate = @PREndDate and Employee = @employee
       	and PaySeq = @pseq
    if @dist <> (@earnings - @dedns)
   		begin
   		select @msg = @msgstart + ' has direct deposit distributions that do not match net pay!', @rcode = 1
   		goto bspexit
   		end
   
   	select @cnt = @cnt + 1	-- # of employees to be paid
   	goto PRSQ_loop
   
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcPRSQ
   		deallocate bcPRSQ
   		end
   
   	if @rcode = 0 and @cnt = 0 
   		begin
   		select @msg = 'No unpaid, eligible Employees found.  If you want to reinitialize payments, first clear existing EFT information.', @rcode = 1
   		end
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREFTProcessCheck] TO [public]
GO
