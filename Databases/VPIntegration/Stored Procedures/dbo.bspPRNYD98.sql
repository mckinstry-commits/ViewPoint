SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNYD98    Script Date: 8/28/99 9:35:33 AM ******/
   
   CREATE     proc [dbo].[bspPRNYD98]
    /********************************************************
    * CREATED BY: 	bc 6/12/98
    * MODIFIED BY:	GH 6/17/99
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 8/10/04 issue 25331  need to check limit so changed focus of routine to return rate rather than calculating and returning amount
    *
    * USAGE:
    * 	Calculates 1998 New York Disability Insurance Fund
    *
    * INPUT PARAMETERS:
    *	@prco		pr company
    *	@subjamt 	subject earnings
    *	@rate_1		prdl rate 1   - women
    *	@rate_2		prdl rate 2	- men
    *	@employee	employee
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated NY disability amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		    failure
    **********************************************************/
    (@prco bCompany, @rate_1 bRate = 0, @rate_2 bRate = 0,
     @employee bEmployee, @rate bRate = 0 output,  @msg varchar(255) = null output)
    as
    set nocount on
   
    declare @rcode int, @procname varchar(30), @gender char(1)
   
    select @rcode = 0, @procname = 'bspPRNYD98'
   
    -- get gender for Employee
    select @gender = Sex from bPREH
   	where PRCo = @prco and Employee = @employee
   
    bspcalc: /* calculate New York City Disability Insurance Fund */
   
    if @gender = 'F' select @rate = @rate_1
    if @gender = 'M' select @rate = @rate_2
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNYD98] TO [public]
GO
