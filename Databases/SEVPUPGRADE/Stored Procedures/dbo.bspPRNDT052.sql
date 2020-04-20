SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNDT052    Script Date: 8/28/99 9:33:29 AM ******/
    CREATE proc [dbo].[bspPRNDT052]
    /********************************************************
    * CREATED BY: 	bc 6/15/98
    * MODIFIED BY:	GG 8/11/98
    *				EN 11/13/01 - issue 15016 - effective 1/1/2002
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 11/11/02 issue 24562  update effective 1/1/2003
    *			 	EN 12/17/02 issue 24562  allowance changed back to 2002 value ($3,050.00)
    *				EN 12/01/03 issue 23129  update effective 1/1/2004
    *				EN 11/24/04 issue 26310  update effective 1/1/2005
    *				EN 1/10/05 - issue 26244  default status and exemptions
    *
    * USAGE:
    * 	Calculates North Dakota Income Tax
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
    @limit bDollar, @rate bRate, @rate1 bRate, @rate2 bRate, @rate3 bRate,
    @rate4 bRate, @rate5 bRate, @procname varchar(30)
    
    select @rcode = 0, @procname = 'bspPRNDT052'
    select @allowance = 3200
    select @rate1 = .021, @rate2 = .0392, @rate3 = .0434, @rate4 = .0504, @rate5 = .0554
    
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
    if @taxincome < 1 select @taxincome = 0
    
    /* determine base tax and rate */
    select @basetax = 0, @limit = 0, @rate = 0
    
    if @status = 'S'
    	begin
    	 if @taxincome > 3400 and @taxincome <= 31500 select @basetax = 0, @limit = 3400, @rate = @rate1
    	 if @taxincome > 31500 and @taxincome <= 66500 select @basetax = 590.10, @limit = 31500, @rate = @rate2
    	 if @taxincome > 66500 and @taxincome <= 152000 select @basetax = 1962.10, @limit = 66500, @rate = @rate3
    	 if @taxincome > 152000 and @taxincome <= 328100 select @basetax = 5672.80, @limit = 152000, @rate = @rate4
    	 if @taxincome > 328100 select @basetax = 14548.24, @limit = 328100, @rate = @rate5
    	end
    
    if @status = 'M'
    	begin
    	 if @taxincome > 8200 and @taxincome <= 56200 select @basetax = 0, @limit = 8200, @rate = @rate1
    	 if @taxincome > 56200 and @taxincome <= 106800 select @basetax = 1008.00, @limit = 56200, @rate = @rate2
    	 if @taxincome > 106800 and @taxincome <= 190000 select @basetax = 2991.52, @limit = 106800, @rate = @rate3
    	 if @taxincome > 190000 and @taxincome <= 333200 select @basetax = 6602.40, @limit = 190000, @rate = @rate4
    	 if @taxincome > 333200 select @basetax = 13819.68, @limit = 333200, @rate = @rate5
    	end
    
    /* calculate tax */
    select @amt = ROUND((@basetax + ((@taxincome - @limit) * @rate)) / @ppds, 0)
    
    if @amt < 0 select @amt = 0
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT052] TO [public]
GO
