SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPHC02    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE    proc [dbo].[bspPRPHC02]
   /********************************************************
   * CREATED BY: 	EN 4/19/02
   * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 3/24/03 - issue 11030 rate of earnings liability limit
   *
   * USAGE:
   * 	Calculates Philadelphia city tax.  For resididents of New Jersey working
   *	in Philadelphia, credits New Jersey state tax for amount paid to Philadelphia tax.
   *
   * INPUT PARAMETERS:
   *	
   *
   * OUTPUT PARAMETERS:
   *	@calcamt	Philadelphia city tax amount
   *	@eligamt	Philadelphia city tax eligible amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   
   *	1 		failure
   **********************************************************/
   (@calcbasis bDollar, @rate bUnitCost, @limitbasis char(1), @limitamt bDollar,
    @ytdcorrect bYN, @limitcorrect bYN, @accumelig bDollar, @accumsubj bDollar,
    @accumamt bDollar, @ytdelig bDollar, @ytdamt bDollar, @prco bCompany, 
    @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint, 
    @calcamt bDollar output, @eligamt bDollar output, @msg varchar(255) = null output)
   
   as
   set nocount on
   
   declare @rcode int, @njdlcode bEDLCode, @njtaxamt bDollar, @procname varchar(30)
   
   select @rcode = 0
   select @procname = 'bspPRPHC02'
   
   -- calc tax as rate of gross using bspPRProcessRateBased
   exec @rcode = bspPRProcessRateBased @calcbasis, @rate, @limitbasis, @limitamt, @ytdcorrect,
                    @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,0,0,0, @calcamt output,
                    @eligamt=@eligamt output, @errmsg=@msg output --issue 11030 adjust for changes in bspPRProcessRateBased
   if @rcode<> 0 goto bspexit
   
   -- if employee is resident of New Jersey, back out city tax amount from New Jersey state tax
   if (select TaxState from bPREH where PRCo = @prco and Employee = @employee) = 'NJ'
   	begin
   	select @njdlcode = TaxDedn from bPRSI where PRCo=@prco and State='NJ'
   	
   	select @njtaxamt = Amount from bPRDT where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   		and Employee = @employee and PaySeq = @payseq and EDLType = 'D' and EDLCode = @njdlcode
   	
   	select @njtaxamt = @njtaxamt - @calcamt
   	if @njtaxamt<0 select @njtaxamt = 0
   	
   	update bPRDT
   	set Amount = @njtaxamt
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   	    and PaySeq = @payseq and EDLType = 'D' and EDLCode = @njdlcode
   	end
   
   
   bspexit:
   	return @rcode
   
   IF OBJECT_ID('dbo.bspPRPHC02') IS NOT NULL
       PRINT '<<< CREATED PROCEDURE dbo.bspPRPHC02 >>>'
   ELSE
       PRINT '<<< FAILED CREATING PROCEDURE dbo.bspPRPHC02 >>>'

GO
GRANT EXECUTE ON  [dbo].[bspPRPHC02] TO [public]
GO
