SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCOO982    Script Date: 8/28/99 9:33:14 AM ******/
     CREATE    proc [dbo].[bspPRCOO982]
     /********************************************************
     * CREATED BY: 	EN 6/4/98
     * MODIFIED BY:	EN 6/4/98
     *		GG 08/15/00 - fixed code to get earnings, added isnull
     *					EN 6/20/03 issue 21574  tax not calced if 1st pay pd of month does not satisfy earnings limit
     *
     * USAGE:
     * 	Calculates Colorado Occupational Privilege Tax
     *	Called from bspPRProcessLocal
     *
     * INPUT PARAMETERS:
     *	@prco	 	PR Company
     *	@dlcode	dedn code for tax
     *	@prgroup	PR group
     *	@prenddate	PR ending date
     *	@employee	Employee
     *	@subjamt	subject earnings
     *
     * OUTPUT PARAMETERS:
     *	@amt		calculated tax amount
     *	@msg		error message if failure
     *
     * RETURN VALUE:
     * 	0 	    	success
     *	1 		failure
     **********************************************************/
     (@prco bCompany, @dlcode bEDLCode, @prgroup bGroup, @prenddate bDate, @employee bEmployee,
      @subjamt bDollar = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
     as
     set nocount on
     
     declare @rcode int, @dltype varchar(1), @rate bUnitCost, @limit bDollar, @limitmth bMonth,
     @aearn bDollar, @updamt bDollar, @procname varchar(30)
     
     select @rcode = 0, @rate = 0, @limit = 0, @aearn = 0, @updamt = 0
     select @procname = 'bspPRCOO982'
     
     /* get dedn type/rate/limit */
     select @dltype=DLType, @rate=RateAmt1, @limit=LimitAmt
     from bPRDL
     where PRCo = @prco and DLCode = @dlcode
     if @@rowcount = 0
         begin
         select @msg = @procname + ':  Deduction code ' + convert(varchar,@dlcode) + 'not set up!', @rcode = 1
         goto bspexit
         end
     
     -- get Limit Month - deduction only taken once per month
     select @limitmth = LimitMth
     from bPRPC
     where PRCo=@prco and PRGroup=@prgroup and PREndDate=@prenddate
     if @@rowcount = 0
         begin
         select @msg = @procname + ':  Missing pay period control information!', @rcode = 1
         goto bspexit
         end
     
     /* get earnings */
   
     select @aearn = isnull(sum(d.EligibleAmt),0), @updamt = isnull(sum(d.Amount),0)
     from bPRDT d
     join bPRPC p on d.PRCo = p.PRCo and d.PRGroup = p.PRGroup and d.PREndDate = p.PREndDate
     where d.PRCo=@prco and d.PRGroup=@prgroup and d.Employee=@employee
         and d.EDLType=@dltype and d.EDLCode=@dlcode  and p.LimitMth = @limitmth
     
     if @updamt <> 0 goto bspexit	-- deduction already taken for the month
     
     --if @aearn = 0 select @aearn = @subjamt
     select @aearn = @aearn + @subjamt -- issue 21574  replaces commented out code above 
    
     /* calculate tax if earnings >= earnings limit */
   
   if @aearn >= @limit select @amt = @rate
     
     bspexit:
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCOO982] TO [public]
GO
