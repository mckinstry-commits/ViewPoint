SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRSQAdjustMethods    Script Date: 8/28/99 9:33:16 AM ******/
    CREATE      proc [dbo].[bspPRSQAdjustMethods]
    /***********************************************************
     * CREATED BY: EN 3/04/04	created for issue 16831
     * MODIFIED By :
     *
     * USAGE:
     * Called from PRPayPeriodControl form when OverrideDirDep
     * flag is changed.
     * Adjusts the pay method on any unpaid entries in bPRSQ
     * in the specified pay period/pay sequence for any employees
     * set up to be paid by direct deposit but marked to be paid
     * by check in bPRSQ.  If pay method was originally directed
     * by the OverrideDirDep flag (see PRPayPeriodControl form)
     * to be set to 'C' (check), change it to 'D' and vice-versa.
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
    
    declare @rcode int
    
    declare @AdjustEmpls table(Employee int)
   
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
   
    -- store Employees to adjust in @AdjustEmpls table variable 
    insert @AdjustEmpls
    select s.Employee from dbo.bPRSQ s with (nolock)
    join dbo.PREH e on e.PRCo=s.PRCo and e.Employee=s.Employee
    where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   	isnull(s.CMRef,'')='' -- unpaid
   	and ((e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=s.PaySeq)) and s.PayMethod='C')
   
   select * from dbo.bPRSQ
   where PRCo=1 and PRGroup=1 and PREndDate='3/7/04' and PaySeq=1 and Employee in (select * from @AdjustEmpls)
   
    
    -- adjust Payment Methods
    if @overridedirdep='Y'
    	begin
   	-- store Employees to adjust in @AdjustEmpls table variable 
   	insert @AdjustEmpls
   	select s.Employee from dbo.bPRSQ s with (nolock)
   	join dbo.PREH e on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')='' -- unpaid
    		-- employee should normally be paid dir dep and is marked to be paid that way in bPRSQ
   		and ((e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=s.PaySeq)) and s.PayMethod='E')
   	-- adjust bPRSQ entries
    	update dbo.bPRSQ
    	set PayMethod='C', ChkType='C'
    	where PRCo=@prco and PRGroup=@prgroup and PREndDate=@prenddate and PaySeq=@payseq and 
    		Employee in (select * from @AdjustEmpls)
    	end
    else
    	begin
   	-- store Employees to adjust in @AdjustEmpls table variable 
   	insert @AdjustEmpls
   	select s.Employee from dbo.bPRSQ s with (nolock)
   	join dbo.PREH e on e.PRCo=s.PRCo and e.Employee=s.Employee
   	where s.PRCo=@prco and s.PRGroup=@prgroup and s.PREndDate=@prenddate and s.PaySeq=@payseq and 
   		isnull(s.CMRef,'')='' -- unpaid
    		-- employee should normally be paid dir dep but is marked to be paid by check in bPRSQ
   		and ((e.DirDeposit='A' and (isnull(e.DDPaySeq,'')='' or e.DDPaySeq=s.PaySeq)) and s.PayMethod='C')
   	-- adjust bPRSQ entries
    	update dbo.bPRSQ
    	set PayMethod='E', ChkType=null
    	where PRCo=@prco and PRGroup=@prgroup and PREndDate=@prenddate and PaySeq=@payseq and 
    		Employee in (select * from @AdjustEmpls)
    	end
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSQAdjustMethods] TO [public]
GO
