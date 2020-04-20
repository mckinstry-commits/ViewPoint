SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRSQUnpaidDDCheck    Script Date: 8/28/99 9:33:16 AM ******/
   CREATE      proc [dbo].[bspPRSQUnpaidDDCheck]
   /***********************************************************
    * CREATED BY: EN 3/04/04	created for issue 16831
    * MODIFIED By :
    *
    * USAGE:
    * Checks for unpaid entries in bPRSQ in the specified
    * pay period/pay sequence for any employees set up to be
    * paid by direct deposit but marked to be paid by check
    * in bPRSQ.
    *
    * INPUT PARAMETERS
    *   prco   	PR Co to validate agains 
    *   prgroup	PR Group
    *	 prenddate	PR Period End Date
    *	 payseq		PR Period Payment Sequence
    *	 overridedirdep	New value of the Override Direct Deposit flag
    *
    * OUTPUT PARAMETERS
    *   @msg      error message
    * RETURN VALUE
    *   0         success (ie. matching entries found)
    *   1         Failure
    *****************************************************/ 
   
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @payseq tinyint, 
    @overridedirdep bYN, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @paidentries int, @unpaidentries int
                
   select @rcode = 0
   
   -- validate inputs
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @prgroup is null
   	begin
   	select @msg = 'Missing PR Group!', @rcode = 1
   	goto bspexit
   	end
   if @prenddate is null
   	begin
   	select @msg = 'Missing PR Period End Date!', @rcode = 1
   	goto bspexit
   	end
   if @payseq is null
   	begin
   	select @msg = 'Missing Payment Sequence!', @rcode = 1
   	goto bspexit
   	end
   
   --check for unpaid PRSQ entries matching the specifications
   if @overridedirdep='Y'
   	begin
   	select @unpaidentries = count(*) from dbo.PRSQ s with (nolock)
   	join dbo.PREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')='' and -- unpaid
   		 -- employee should normally be paid dir dep and is marked to be paid that way in bPRSQ
   		((e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=@payseq)) and s.PayMethod='E')
   	end
   else
   	begin
   	select @unpaidentries = count(*) from dbo.PRSQ s with (nolock)
   	join dbo.PREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')='' and -- unpaid
   		 -- employee should normally be paid dir dep but is marked to be paid by check in bPRSQ
   		((e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=@payseq)) and s.PayMethod='C')
   	end
   if isnull(@unpaidentries,0) <> 0
   	begin
   	select @msg = 'Matching unpaid PRSQ entries found!', @rcode = 1
   	goto bspexit
   	end
   
   --check for paid PRSQ entries matching the specifications
   if @overridedirdep='Y'
   	begin
   	select @paidentries = count(*) from dbo.PRSQ s with (nolock)
   	join dbo.PREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')<>'' and -- paid
   		 -- employee should normally be paid dir dep and is marked to be paid that way in bPRSQ
   		((e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=@payseq)) and s.PayMethod='E')
   	select @unpaidentries = count(*) from dbo.PRSQ s with (nolock)
   	join dbo.PREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')='' and -- unpaid
   		 -- employee should normally be paid dir dep
   		(e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=@payseq))
   	end
   else
   	begin
   	select @paidentries = count(*) from dbo.PRSQ s with (nolock)
   	join dbo.PREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')<>'' and -- paid
   		 -- employee should normally be paid dir dep but is marked to be paid by check in bPRSQ
   		((e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=@payseq)) and s.PayMethod='C')
   	select @unpaidentries = count(*) from dbo.PRSQ s with (nolock)
   	join dbo.PREH e with (nolock) on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')='' and -- unpaid
   		 -- employee should normally be paid dir dep
   		(e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=@payseq))
   	end
   if isnull(@unpaidentries,0) = 0 and isnull(@paidentries,0) <> 0
   	begin
   	select @msg = 'Only matching paid PRSQ entries found!', @rcode = 2
   	goto bspexit
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSQUnpaidDDCheck] TO [public]
GO
