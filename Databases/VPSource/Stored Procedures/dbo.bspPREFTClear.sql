SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPREFTClear]
   /***********************************************************
    * CREATED: GG 07/25/02 - #17998
    * MODIFIED: 
    *
    * USAGE:
    * 	Called by PR EFT Download form to clear existing EFT payment info 
    *
    * INPUT PARAMETERS
    *  @prco			PR Company #
    *  @prgroup		PR Group number being processed
    *  @prenddate		Pay Period ending date
    *	@cmref			CM Reference # to restrict, if null then all
    *
    * OUTPUT PARAMETERS
    *   @msg      		error message
    *
    * RETURN VALUE
    *  0   	success
    *  1   	fail
    *******************************************************************/
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	 @cmref bCMRef = null, @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode tinyint, @status tinyint
    
   select @rcode = 0
   
   /* validate inputs */
   if @prco is null
   	begin
       select @msg = 'Missing PR Company number!', @rcode = 1
       goto bspexit
       end
   if @prgroup is null
    	begin
    	select @msg = 'Missing PR Group!', @rcode = 1
    	goto bspexit
    	end
   if @prenddate is null
    	begin
    	select @msg = 'Missing Pay Period Ending Date!', @rcode = 1
    	goto bspexit
    	end
   select @status = Status
   from bPRPC
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
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
   	
   
   begin transaction
   
   -- add an entry to PR Void Payments if already interfaced to CM - needed to reverse
   insert bPRVP(PRCo, PRGroup, PREndDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq,
   	EFTSeq, ChkType, PaidDate, PaidMth, Employee, PaidAmt, VoidMemo, Reuse, PaySeq,
   	Hours, Earnings, Dedns)
   select PRCo, PRGroup, PREndDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq,
   	EFTSeq, ChkType, PaidDate, PaidMth, Employee, (Earnings - Dedns), null, 'Y', PaySeq,
   	Hours, Earnings, Dedns
   from bPRSQ
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    	and CMRef = isnull(@cmref,CMRef) and CMRef is not null and PayMethod = 'E'
   	and CMInterface = 'Y'
   
   -- clear payment information in PR Sequence Control, reset CMInterface flag 
   update bPRSQ
   set CMRef = null, CMRefSeq = null, EFTSeq = null, PaidDate = null, PaidMth = null, Hours = 0,
   	Earnings = 0, Dedns = 0, CMInterface = 'N'
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate 
   	and CMRef = isnull(@cmref,CMRef) and CMRef is not null and PayMethod = 'E'
   
   commit transaction
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREFTClear] TO [public]
GO
