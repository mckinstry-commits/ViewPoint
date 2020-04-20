SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPROST98    Script Date: 8/28/99 9:35:33 AM ******/
    
     CREATE     proc [dbo].[bspPROST98]
     /********************************************************
     * CREATED BY: 	bc 6/11/98
     * MODIFIED BY:	GG 11/13/98
     *					EN 3/19/02 - issue 16608 Look up fed tax dedn code in bPRFI and use it to get the fed basis
     *					EN 10/8/02 - issue 18877 change double quotes to single
     *
     * USAGE:
     * 	Calculates 1998 Ohio School District Tax
     *
     * INPUT PARAMETERS:
     *	@prco		Payroll Company
     *	@prgroup	PR Group of this employee
     *	@enddate	Payroll ending date
     *	@payseq		Payment Sequence
     *	@employee	Employee
     *	@ppds		# of pay periods in a year
     *	@rate		resident or nonresident rate paid for this school district tax
     *
     * OUTPUT PARAMETERS:
     *	@amt		calculated Fed tax amount
     *	@subjamt	subject amount for Ohio only
     *	@subjaccm	subject accumulation for Ohio only
     *	@msg		error message if failure
     *
     * RETURN VALUE:
     * 	0 	    	success
     *	1 		failure
     **********************************************************/
     	(@prco bCompany = null, @prgroup bGroup = null, @enddate bDate = null, @payseq tinyint = 0,
     	 @employee bEmployee = null, @ppds tinyint = 0, @rate bRate = 0, @amt bDollar = 0 output,
      	 @subjamt bDollar = 0 output, @subjaccm bDollar = 0 output, @msg varchar(255) = null output)
    
     as
   
     set nocount on
    
     declare @rcode int, @temp bDollar, @procname varchar(30), @allowance bDollar, 
   	@feddedn bEDLCode, @ohdedn bEDLCode, @exempts tinyint
    
     select @rcode = 0, @allowance = 650, @exempts = 0, @procname = 'bspPROST98'
   
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
     	goto bspexit
     	end
    
     -- get federal Tax Deduction code
     select @feddedn = TaxDedn
     from bPRFI
     where PRCo = @prco
     if @@rowcount = 0
     	begin
     	select @msg = @procname + ':  Federal deduction code not set up!', @rcode = 1
     	goto bspexit
     	end
   
     -- get Ohio State Tax Deduction code
     select @ohdedn = TaxDedn
     from bPRSI
     where PRCo = @prco and State = 'OH'
     if @@rowcount = 0
     	begin
     	select @msg = @procname + ':  Ohio state deduction code not set up!', @rcode = 1
     	goto bspexit
     	end
   
     -- get earnings subject to federal tax
     select @subjamt = SubjectAmt
     from bPRDT
     where PRCo = @prco and PRGroup = @prgroup and PREndDate = @enddate and Employee = @employee and
        	     PaySeq = @payseq and EDLType = 'D' and EDLCode = @feddedn
     if @@rowcount = 0 goto bspexit
    
     if @subjamt = 0 goto bspexit
   
     -- get # of exemptions for Ohio State Tax
     select @exempts = RegExempts
     from bPRED
     where PRCo = @prco and Employee = @employee and DLCode = @ohdedn
    
     bspcalc: -- calculate Ohio School District Tax
     	select  @temp = ((@subjamt * @ppds) - (@exempts * @allowance)) / @ppds
    
      	select @amt = @rate * @temp
     	select @subjaccm = @subjamt
    
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROST98] TO [public]
GO
