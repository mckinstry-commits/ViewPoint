SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRKST07    Script Date: 8/28/99 9:33:24 AM ******/
 CREATE proc [dbo].[bspPRKST07]
 /********************************************************
 * CREATED BY: 	EN 6/5/98
 * MODIFIED BY:	EN 12/16/98
 *				EN 10/8/02 - issue 18877 change double quotes to single
 *				EN 1/4/05 - issue 26244  default status and exemptions
 *				EN 1/2/07 - issue 123428  update allowance from $2,000 to $2,250.
 *				EN 1/3/07 - issue 123428  additional change to round tax to nearest dollar
 *
 * USAGE:
 * 	Calculates Kansas Income Tax
 *
 * INPUT PARAMETERS:
 *	@subjamt 	subject earnings
 *	@ppds		# of pay pds per year
 *	@status		filing status
 *	@exempts	# of exemptions
 *
 * OUTPUT PARAMETERS:
 *	@amt		calculated tax amount
 *	@msg		error message if failure
 *
 * RETURN VALUE:
 * 	0 	    	success
 *	1 		failure
 **********************************************************/
 (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
  @amt bDollar = 0 output, @msg varchar(255) = null output)
 as
 set nocount on
 
 declare @rcode int, @taxincome bDollar, @allowance bDollar, @basetax bDollar,
 @limit bDollar, @rate bRate, @procname varchar(30)
 
 select @rcode = 0, @allowance = 2250
 select @procname = 'bspPRKST07'
 
 -- #26244 set default status and/or exemptions if passed in values are invalid
 if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
 if @exempts is null select @exempts = 0
 
 if @ppds = 0
 	begin
 	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
 
 	goto bspexit
 	end
 
 /* determine taxable income */
 select @taxincome = (@subjamt * @ppds) - (@exempts * @allowance)
 if @taxincome < 0 select @taxincome = 0
 
 /* determine base tax and rate */
 select @basetax = 0, @limit = 0, @rate = 0
 
 if @status = 'S'
 	begin
 	 if @taxincome > 3000 and @taxincome <= 18000 select @basetax = 0, @limit = 3000, @rate = .035
 	 if @taxincome > 18000 and @taxincome <= 33000 select @basetax = 525, @limit = 18000, @rate = .0625
 	 if @taxincome > 33000 select @basetax = 1462.5, @limit = 33000, @rate = .0645
 	end
 
 if @status = 'M'
 	begin
 	 if @taxincome > 6000 and @taxincome <= 36000 select @basetax = 0, @limit = 6000, @rate = .035
 	 if @taxincome > 36000 and @taxincome <= 66000 select @basetax = 1050, @limit = 36000, @rate = .0625
 	 if @taxincome > 66000 select @basetax = 2925, @limit = 66000, @rate = .0645
 	end
 	
 /* calculate tax */
 select @amt = round((@basetax + (@taxincome - @limit) * @rate) / @ppds,0)
 if @amt < 0 select @amt = 0
 
 
 bspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRKST07] TO [public]
GO
