SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRINC98    Script Date: 8/28/99 9:33:23 AM ******/
    CREATE   proc [dbo].[bspPRINC98]
    /********************************************************
    * CREATED BY: 	EN 6/6/98
    * MODIFIED BY: GG 12/16/98
    *              EN 3/20/01 - issue 12748 - use addl exemption to calculate dependent exemption
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * 	Calculates Indiana County Tax
    *	Called from bspPRProcessLocal
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@exempts	# of exemptions
    *	@rate		county tax rate
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    (@subjamt bDollar = 0, @ppds tinyint = 0, @exempts tinyint = 0, @addexempts tinyint = 0,
     @rate bUnitCost = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
   
    declare @rcode int, @taxincome bDollar, @regallowance bDollar, @depallowance bDollar, @procname varchar(30)
   
    select @rcode = 0, @regallowance = 1000, @depallowance = 1500
    select @procname = 'bspPRINC98'
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
   
    /* determine taxable income */
    select @taxincome = (@subjamt * @ppds) - (@exempts * @regallowance) - (@addexempts * @depallowance)
    if @taxincome < 0 select @taxincome = 0
   
    /* calculate tax */
    select @amt = (@taxincome * @rate) / @ppds
    if @amt < 0 select @amt = 0
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRINC98] TO [public]
GO
